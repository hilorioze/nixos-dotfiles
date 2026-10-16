{config, ...}: {
  sops = {
    secrets."credentials/cloudflare/zones/hilorioze.com/api-token" = {};

    templates."services/cloudflare-ddns.env" = {
      content = ''
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder."credentials/cloudflare/zones/hilorioze.com/api-token"}
      '';

      owner = config.services.cloudflare-ddns.user;
    };
  };

  services.cloudflare-ddns = {
    enable = true;

    credentialsFile = config.sops.templates."services/cloudflare-ddns.env".path;

    domains = [config.networking.fqdn];

    provider = {
      ipv4 = "local";
      ipv6 = "none";
    };

    updateCron = "@once";
  };
}
