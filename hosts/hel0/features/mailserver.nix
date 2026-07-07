{
  # keep-sorted start
  config,
  inputs,
  lib,
  # keep-sorted end
  ...
}: let
  inherit (config.networking) domain fqdn;

  baseDN = "dc=${lib.concatStringsSep ",dc=" (lib.splitString "." domain)}";
  imapHost = "imap.${domain}";
in {
  imports = [inputs.simple-nixos-mailserver.nixosModules.default];

  sops.secrets."services/rspamd/dkim/${domain}/private-key".owner = config.services.rspamd.user;

  mailserver = {
    enable = true;

    stateVersion = 5;

    fqdn = imapHost;
    sendingFqdn = fqdn; # must match rDNS of the server's IP

    systemDomain = domain;
    domains = [domain];

    storage = {
      directoryLayout = "fs";
      path = "/var/lib/mail";

      owner = "vmail";
      group = "vmail";
    };

    indexDir = "/var/lib/mail-index";

    ldap = {
      enable = true;

      uris = ["ldap://127.0.0.1"];

      bind = {
        dn = "cn=mailserver,ou=services,${baseDN}";

        passwordFile = config.sops.secrets."services/openldap/${domain}/services/mailserver/password".path;
      };

      base = "ou=accounts,${baseDN}";

      dovecot = {
        userFilter = "(&(objectClass=inetOrgPerson)(|(mail=%{user})(mailAlias=%{user})(uid=%{user})))";
        passFilter = "(&(objectClass=inetOrgPerson)(|(mail=%{user})(mailAlias=%{user})(uid=%{user})))";
      };

      postfix.filter = "(&(objectClass=inetOrgPerson)(|(mail=%s)(mailAlias=%s)))";
    };

    enableSubmission = true;
    enableManageSieve = true;

    hierarchySeparator = "/";

    dkim = {
      enable = true;

      domains."${domain}".selectors.mail.keyFile = config.sops.secrets."services/rspamd/dkim/${domain}/private-key".path;
    };

    dmarcReporting.enable = true;

    fullTextSearch = {
      enable = true;

      fallback = false;
    };

    mailboxes = {
      # keep-sorted start block=yes newline_separated=yes
      Archive = {
        auto = "subscribe";
        special_use = "\\Archive";
      };

      Drafts = {
        auto = "subscribe";
        special_use = "\\Drafts";
      };

      Junk = {
        auto = "subscribe";
        special_use = "\\Junk";

        fts_autoindex = false;
      };

      Sent = {
        auto = "subscribe";
        special_use = "\\Sent";
      };

      Trash = {
        auto = "no";
        special_use = "\\Trash";

        fts_autoindex = false;
      };
      # keep-sorted end
    };

    # `postmaster@${domain}` aliases to `root@${domain}` in LDAP, but postfix does not re-expand it after alias resolution.
    forwards."postmaster@${domain}" = ["root@${domain}"];

    x509.useACMEHost = imapHost;
  };

  services.dovecot2.settings."passdb ldap" = {
    bind = true;

    # normalize the authenticated username so postfix sees the same identity no matter whether the client logs in with uid, primary mail, or alias
    fields = lib.mkForce {
      user = "%{ldap:${config.mailserver.ldap.attributes.username}}";
    };
  };

  security.acme.certs."${imapHost}" = {
    extraDomainNames = ["smtp.${domain}"];

    dnsProvider = "cloudflare";

    credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."credentials/cloudflare/zones/${domain}/dns01-token".path;
  };
}
