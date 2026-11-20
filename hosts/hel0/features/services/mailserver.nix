{
  # keep-sorted start
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: let
  inherit (config.networking) domain fqdn;

  imapHost = "imap.${domain}";

  ldapURI = "ldaps://${outputs.nixosConfigurations.de0.config.networking.fqdn}:6636";

  ldapBaseDN = "DC=ldap,DC=goauthentik,DC=io";
  ldapUsersDN = "ou=users,${ldapBaseDN}";
  ldapBindDN = "cn=mail-directory,${ldapUsersDN}";
  ldapGroupDN = "cn=mail-users,ou=groups,${ldapBaseDN}";

  ldapBindSecret = "services/mailserver/ldap-bind-password";
in {
  imports = [inputs.simple-nixos-mailserver.nixosModules.default];

  sops = {
    secrets = {
      # keep-sorted start block=yes newline_separated=yes
      "services/rspamd/dkim/${domain}/private-key" = {
        owner = config.services.rspamd.user;

        restartUnits = ["rspamd.service"];
      };

      ${ldapBindSecret}.restartUnits = ["dovecot.service"]; # postfix requires dovecot and restarts with it
      # keep-sorted end
    };

    templates."services/postfix/ldap" = {
      content = ''
        server_host = ${ldapURI}
        version = 3
        search_base = ${ldapUsersDN}

        bind = yes
        bind_dn = ${ldapBindDN}
        bind_pw = ${config.sops.placeholder.${ldapBindSecret}}

        query_filter = (&(objectClass=inetOrgPerson)(mail=%s)(memberOf=${ldapGroupDN}))
        result_attribute = mail
      '';

      owner = config.services.postfix.user;
    };
  };

  mailserver = {
    enable = true;

    stateVersion = 5;

    fqdn = imapHost;
    sendingFqdn = fqdn; # must match rdns of the server's ip

    systemDomain = domain;
    domains = [domain];

    storage = {
      directoryLayout = "fs";
      path = "/var/lib/mail";

      owner = "vmail";
      group = "vmail";
    };

    indexDir = "/var/lib/mail-index";

    forwards."@${domain}" = "hilorioze@${domain}"; # catch-all for non-existing mailboxes

    enableManageSieve = true;

    hierarchySeparator = "/";

    dkim = {
      enable = true;

      domains.${domain}.selectors.mail.keyFile = config.sops.secrets."services/rspamd/dkim/${domain}/private-key".path;
    };

    fullTextSearch = {
      enable = true;

      fallback = false;
    };

    x509.useACMEHost = imapHost;
  };

  services = {
    dovecot2.settings = {
      auth_mechanisms = lib.mkForce ["xoauth2"];

      "service lmtp".service_extra_groups = ["dovecot2"];

      "passdb declarative" = lib.mkForce null;
      "userdb declarative" = lib.mkForce null;

      ldap_uris = [ldapURI];

      ldap_base = ldapUsersDN;

      ldap_auth_dn = ldapBindDN;
      ldap_auth_dn_password = "</run/credentials/dovecot.service/ldap-bind-password";

      ssl_client_require_valid_cert = false;

      "userdb ldap" = {
        driver = "ldap";

        filter = "(&(objectClass=inetOrgPerson)(mail=%{user})(memberOf=${ldapGroupDN}))";

        fields = let
          mailboxPath = "%{user | domain}/%{user | username}";
        in {
          home = "${config.mailserver.storage.path}/${mailboxPath}";
          mail_index_path = "${config.mailserver.indexDir}/${mailboxPath}";

          inherit (config.mailserver.storage) uid gid;
        };
      };

      oauth2 = {
        oauth2_introspection_mode = "auth";
        oauth2_introspection_url = "https://idm.${domain}/application/o/userinfo/";

        oauth2_active_attribute = "mail_access";
        oauth2_active_value = "true";
      };

      # replace nixos-mailserver's junk filter to also flag the spam it files
      "sieve_script spamfilter".path = lib.mkForce (pkgs.writeText "after.sieve" ''
        require ["fileinto", "imap4flags"];

        # thunderbird takes the `Junk` keyword as its junk mark; `\Seen` keeps `Junk` from showing an unread count
        if header :is "X-Spam" "Yes" {
            fileinto :flags ["\\Seen", "Junk"] "Junk";
            stop;
        }
      '');
    };

    postfix = let
      postfixLdapMap = "ldap:${config.sops.templates."services/postfix/ldap".path}";
    in {
      settings.main.virtual_mailbox_maps = lib.mkForce [postfixLdapMap];

      submissionsOptions = {
        line_length_limit = "12288";

        smtpd_sender_login_maps = lib.mkForce postfixLdapMap;
      };
    };

    rspamd.locals = {
      "actions.conf".text = "reject = null;"; # file all spam into `Junk` instead of rejecting it

      # mark spam with the spamassassin header thunderbird trusts; it doesn't know rspamd's `X-Spam`
      # ucl appends this `use` to the one nixos-mailserver sets
      "milter_headers.conf".text = ''
        use = ["spam-header"];

        routines {
          spam-header {
            header = "X-Spam-Flag";
            value = "YES";
          }
        }
      '';

      # learn obvious spam and clear ham on its own; spam that reached the mailbox never scored below -1
      "classifier-bayes.conf".text = ''
        autolearn {
          # without `reject` every spam verdict is junk; rspamd checks `junk_threshold` only when `spam_threshold` is set too
          spam_threshold = 15;
          junk_threshold = 15;
          ham_threshold = -3;

          check_balance = true;
        }
      '';
    };
  };

  security.acme.certs.${imapHost} = {
    extraDomainNames = ["mail.${domain}" "smtp.${domain}"]; # `mail` for the mx; mta-sts checks it against the certificate

    dnsProvider = "cloudflare";

    credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."credentials/cloudflare/zones/${domain}/api-token".path;
  };

  systemd = {
    # nixos-mailserver leaves empty reporter units when reporting is disabled
    timers.rspamd-dmarc-reporter.enable = false;

    services = {
      dovecot.serviceConfig.LoadCredential = ["ldap-bind-password:${config.sops.secrets.${ldapBindSecret}.path}"];

      rspamd-dmarc-reporter.enable = false;
    };
  };
}
