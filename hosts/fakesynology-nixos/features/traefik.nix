{config, ...}: let
  httpPort = 80;
  httpsPort = 443;
in {
  imports = [../../common/features/traefik.nix];

  sops = {
    secrets."credentials/cloudflare/zones/hilorioze.com/api-token" = {};

    templates."services/traefik/cloudflare.env".content = "CF_DNS_API_TOKEN=${config.sops.placeholder."credentials/cloudflare/zones/hilorioze.com/api-token"}";
  };

  networking.firewall = {
    allowedTCPPorts = [
      # keep-sorted start numeric=yes
      httpPort
      httpsPort
      # keep-sorted end
    ];

    allowedUDPPorts = [httpsPort];
  };

  services.traefik = {
    environmentFiles = ["${config.sops.templates."services/traefik/cloudflare.env".path}"];

    staticConfigOptions = {
      entryPoints = {
        # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=address\s*=\s*[^;]*?:(\d+)
        http.address = ":80";

        https = {
          address = ":443";

          http.tls.certResolver = "cloudflare";

          http3 = {};
        };
        # keep-sorted end
      };

      certificatesResolvers.cloudflare.acme = {
        email = "me@hilorioze.com";

        dnsChallenge.provider = "cloudflare";
      };
    };
  };
}
