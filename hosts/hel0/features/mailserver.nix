{config, ...}: let
  inherit (config.networking) domain;
  mailHost = "imap.${domain}";
in {
  imports = [../../common/features/mailserver.nix];

  mailserver.x509.useACMEHost = mailHost;

  sops.secrets."services/rspamd/dkim/${domain}/private-key" = {
    owner = config.services.rspamd.user;
    inherit (config.services.rspamd) group;
  };

  security.acme.certs."${mailHost}" = {
    dnsProvider = "cloudflare";
    credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."credentials/cloudflare/zones/${domain}/dns01".path;
    extraDomainNames = [config.mailserver.sendingFqdn];
  };
}
