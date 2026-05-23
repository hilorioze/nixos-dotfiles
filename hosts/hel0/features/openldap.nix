{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  inherit (config.networking) domain;
  baseDN = "dc=${lib.concatStringsSep ",dc=" (lib.splitString "." domain)}";

  users =
    lib.mapAttrs (uid: attrs: {
      inherit uid;
      cn = attrs.cn or uid;
      sn = attrs.sn or uid;
      displayName = attrs.displayName or null;
      givenName = attrs.givenName or null;
      mail = attrs.mail or "${uid}@${domain}";
      mailAliases = attrs.mailAliases or [];
      groups = attrs.groups or [];
    }) {
      # keep-sorted start block=yes newline_separated=yes
      hilorioze = {
        cn = "hilorioze";
        displayName = "hilorioze";
        sn = "hilorioze";
        mail = "me@${domain}";
        mailAliases = [
          # keep-sorted start
          "contact@${domain}"
          "hilorioze@${domain}"
          "support@${domain}"
          "yan@${domain}" # old primary, kept as an alias
          # keep-sorted end
        ];
        groups = ["mail-access"];
      };

      root = {
        mail = "root@${domain}";
        mailAliases = ["postmaster@${domain}"];
        groups = ["mail-access"];
      };
      # keep-sorted end
    };

  groups =
    lib.genAttrs
    (lib.unique (lib.flatten (map (user: user.groups) (lib.attrValues users))))
    (group: lib.attrNames (lib.filterAttrs (_uid: user: builtins.elem group user.groups) users));

  # service accounts for applications that need LDAP access
  serviceAccounts = [
    # keep-sorted start
    "mailserver"
    # keep-sorted end
  ];

  # custom LDAP schema: separates primary mail from aliases
  mailAccountSchema = pkgs.writeText "mail-account.ldif" ''
    dn: cn=mailaccount,cn=schema,cn=config
    objectClass: olcSchemaConfig
    cn: mailaccount
    olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.1.1 NAME 'mailAlias' DESC 'Mail alias address' EQUALITY caseIgnoreIA5Match SUBSTR caseIgnoreIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{256} )
    olcObjectClasses: ( 1.3.6.1.4.1.99999.1.2.1 NAME 'mailAccount' DESC 'Mail account with aliases' SUP top AUXILIARY MAY mailAlias )
  '';

  mkUserDN = uid: "uid=${uid},ou=accounts,${baseDN}";
  mkServiceDN = cn: "cn=${cn},ou=services,${baseDN}";

  mkUserLdif = uid: user:
    lib.concatStringsSep "\n" (lib.filter (s: s != "") ([
        "dn: ${mkUserDN uid}"
        "objectClass: inetOrgPerson"
        (lib.optionalString (user.mailAliases != []) "objectClass: mailAccount")
        "uid: ${uid}"
        "cn: ${user.cn}"
        "sn: ${user.sn}"
        (lib.optionalString (user.displayName != null) "displayName: ${user.displayName}")
        (lib.optionalString (user.givenName != null) "givenName: ${user.givenName}")
        "mail: ${user.mail}"
      ]
      ++ map (alias: "mailAlias: ${alias}") user.mailAliases));

  mkGroupLdif = name: members:
    lib.concatStringsSep "\n" ([
        "dn: cn=${name},ou=roles,${baseDN}"
        "objectClass: groupOfNames"
        "cn: ${name}"
      ]
      ++ map (uid: "member: ${mkUserDN uid}") members);

  mkServiceLdif = cn:
    lib.concatStringsSep "\n" [
      "dn: ${mkServiceDN cn}"
      "objectClass: simpleSecurityObject"
      "objectClass: organizationalRole"
      "cn: ${cn}"
      "userPassword: x" # dummy password, overwritten by postStart
      "description: Service account for ${cn}"
    ];
in {
  imports = [
    ../../common/features/openldap.nix
  ];

  sops.secrets =
    lib.mapAttrs' (
      uid: _user:
        lib.nameValuePair
        "services/openldap/${domain}/users/${uid}/password"
        {
          owner = config.services.openldap.user;
          inherit (config.services.openldap) group;
        }
    )
    users
    // lib.listToAttrs (map (cn:
      lib.nameValuePair
      "services/openldap/${domain}/services/${cn}/password"
      {
        owner = config.services.openldap.user;
        inherit (config.services.openldap) group;
      })
    serviceAccounts);

  networking.firewall.allowedTCPPorts = [636];

  services.traefik = {
    staticConfigOptions.entryPoints.ldaps.address = ":636";
    dynamicConfigOptions.tcp = {
      routers.openldap = {
        entryPoints = ["ldaps"];
        tls.certResolver = "cloudflare";
        rule = "HostSNI(`ldap.${domain}`)";
        service = "openldap";
      };
      services.openldap.loadBalancer.servers = [{address = "127.0.0.1:389";}];
    };
  };

  services.openldap = {
    urlList = ["ldap://127.0.0.1/" "ldapi:///"];

    settings.children = {
      "cn=module{0}".attrs = {
        objectClass = "olcModuleList";
        cn = "module{0}";
        olcModulePath = "${pkgs.openldap}/lib/openldap";
        olcModuleLoad = "memberof";
      };

      "cn=schema".includes = [
        "${pkgs.openldap}/etc/schema/core.ldif"
        "${pkgs.openldap}/etc/schema/cosine.ldif"
        "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
        mailAccountSchema
      ];

      "olcDatabase={1}mdb" = {
        attrs = {
          objectClass = ["olcDatabaseConfig" "olcMdbConfig"];
          olcDatabase = "{1}mdb";
          olcDbDirectory = "/var/lib/openldap/${domain}";
          olcSuffix = baseDN;
          olcRootDN = "cn=root,${baseDN}";
          olcRootPW.path = config.sops.secrets."services/openldap/${domain}/users/root/password".path;

          olcDbIndex = [
            "objectClass eq"
            "uid pres,eq"
            "mail pres,eq,sub"
            "mailAlias pres,eq"
            "cn pres,eq,sub"
          ];

          olcAccess = [
            # password authentication requires anonymous auth; only owner can modify
            "{0}to attrs=userPassword by self write by anonymous auth by * none"

            # service accounts can read user attributes for authentication lookups
            "{1}to attrs=mail,mailAlias,cn,sn,uid,givenName,displayName by dn.subtree=\"ou=services,${baseDN}\" read by users read"

            # service accounts can read all user data, users can read only their own
            "{2}to dn.subtree=\"ou=accounts,${baseDN}\" by dn.subtree=\"ou=services,${baseDN}\" read by self read by * none"

            # default: users can read only their own data
            "{3}to * by self read by * none"
          ];
        };

        children."olcOverlay={0}memberof".attrs = {
          objectClass = ["olcOverlayConfig" "olcMemberOf"];
          olcOverlay = "{0}memberof";
          olcMemberOfRefInt = "TRUE";
          olcMemberOfGroupOC = "groupOfNames";
          olcMemberOfMemberAD = "member";
          olcMemberOfMemberOfAD = "memberOf";
        };
      };
    };

    declarativeContents.${baseDN} = ''
      dn: ${baseDN}
      objectClass: domain
      dc: ${builtins.head (lib.splitString "." domain)}

      dn: ou=accounts,${baseDN}
      objectClass: organizationalUnit
      ou: accounts

      ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList mkUserLdif users)}

      dn: ou=services,${baseDN}
      objectClass: organizationalUnit
      ou: services

      ${lib.concatStringsSep "\n\n" (map mkServiceLdif serviceAccounts)}

      dn: ou=roles,${baseDN}
      objectClass: organizationalUnit
      ou: roles

      ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList mkGroupLdif groups)}
    '';
  };

  systemd.services.openldap.postStart = lib.mkAfter (let
    rootPasswordFile = config.sops.secrets."services/openldap/${domain}/users/root/password".path;
  in ''
    for i in {1..30}; do
      if ${lib.getExe' pkgs.openldap "ldapsearch"} -x -H ldapi:/// \
        -D "cn=root,${baseDN}" -y ${rootPasswordFile} \
        -b "${baseDN}" -s base >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (uid: _user: ''
        if ${lib.getExe' pkgs.openldap "ldapsearch"} -x -H ldapi:/// \
          -D "cn=root,${baseDN}" -y ${rootPasswordFile} \
          -b "${mkUserDN uid}" -s base dn >/dev/null 2>&1; then
          ${lib.getExe' pkgs.openldap "ldappasswd"} -x -H ldapi:/// \
            -D "cn=root,${baseDN}" \
            -y ${rootPasswordFile} \
            -T ${config.sops.secrets."services/openldap/${domain}/users/${uid}/password".path} \
            "${mkUserDN uid}"
        fi
      '')
      users)}

    # Set passwords for service accounts
    ${lib.concatStringsSep "\n" (map (cn: ''
        if ${lib.getExe' pkgs.openldap "ldapsearch"} -x -H ldapi:/// \
          -D "cn=root,${baseDN}" -y ${rootPasswordFile} \
          -b "${mkServiceDN cn}" -s base dn >/dev/null 2>&1; then
          ${lib.getExe' pkgs.openldap "ldappasswd"} -x -H ldapi:/// \
            -D "cn=root,${baseDN}" \
            -y ${rootPasswordFile} \
            -T ${config.sops.secrets."services/openldap/${domain}/services/${cn}/password".path} \
            "${mkServiceDN cn}"
        fi
      '')
      serviceAccounts)}
  '');
}
