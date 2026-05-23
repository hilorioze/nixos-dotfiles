{config, ...}: {
  sops = {
    secrets."credentials/cloudflare/zones/hilorioze.com/api-token" = {};

    templates."config/cloudflare-ddns.env" = {
      content = ''
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder."credentials/cloudflare/zones/hilorioze.com/api-token"}
      '';

      owner = config.services.cloudflare-ddns.user;
    };
  };

  services.cloudflare-ddns = {
    enable = true;

    credentialsFile = config.sops.templates."config/cloudflare-ddns.env".path;

    domains = [config.networking.fqdn];

    provider = {
      ipv4 = "local";
      ipv6 = "local";
    };

    updateCron = "@once";
  };
}
