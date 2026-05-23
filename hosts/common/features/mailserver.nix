{
  # keep-sorted start
  config,
  inputs,
  lib,
  # keep-sorted end
  ...
}: let
  inherit (config.networking) domain;

  baseDN = "dc=${lib.concatStringsSep ",dc=" (lib.splitString "." domain)}";
  mailHost = "imap.${domain}";
  smtpHost = "smtp.${domain}";
in {
  imports = [inputs.simple-nixos-mailserver.nixosModule];

  mailserver = {
    enable = true;
    stateVersion = 4;

    fqdn = mailHost;
    sendingFqdn = smtpHost;
    systemDomain = domain;
    domains = [domain];

    storage = {
      path = "/var/lib/mail";
      owner = "vmail";
      group = "vmail";
      uid = 5000;
      gid = 5000;
      directoryLayout = "fs";
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
      scope = "sub";

      dovecot = {
        userFilter = "(&(objectClass=inetOrgPerson)(|(mail=%{user})(mailAlias=%{user})(uid=%{user})))";
        passFilter = "(&(objectClass=inetOrgPerson)(|(mail=%{user})(mailAlias=%{user})(uid=%{user})))";
      };

      postfix.filter = "(&(objectClass=inetOrgPerson)(|(mail=%s)(mailAlias=%s)))";
    };

    enableImap = false;
    enableImapSsl = true;
    enableSubmission = true;
    enableSubmissionSsl = true;
    enablePop3 = false;
    enablePop3Ssl = false;
    enableManageSieve = true;

    hierarchySeparator = "/";

    dkim = {
      enable = true;
      domains."${domain}".selectors.mail.keyFile = config.sops.secrets."services/rspamd/dkim/${domain}/private-key".path;
    };

    dmarcReporting.enable = true;

    debug.dovecot = false;

    fullTextSearch = {
      enable = true;
      autoIndex = true;
      fallback = false;
    };

    mailboxes = {
      Trash = {
        auto = "no";
        special_use = "\\Trash";
        fts_autoindex = false;
      };
      Junk = {
        auto = "subscribe";
        special_use = "\\Junk";
        fts_autoindex = false;
      };
      Drafts = {
        auto = "subscribe";
        special_use = "\\Drafts";
      };
      Sent = {
        auto = "subscribe";
        special_use = "\\Sent";
      };
      Archive = {
        auto = "subscribe";
        special_use = "\\Archive";
      };
    };
  };

  services.dovecot2.settings."passdb ldap" = {
    bind = true;
    fields = lib.mkForce {};
  };
}
