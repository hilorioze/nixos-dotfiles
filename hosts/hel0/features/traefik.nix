{config, ...}: {
  imports = [../../common/features/traefik.nix];

  sops = {
    secrets."credentials/cloudflare/zones/hilorioze.com/dns01-token" = {};

    templates."services/traefik/cloudflare.env".content = "CF_DNS_API_TOKEN=${config.sops.placeholder."credentials/cloudflare/zones/hilorioze.com/dns01-token"}";
  };

  networking.firewall = {
    allowedTCPPorts = [
      # keep-sorted start numeric=yes
      80
      443
      5000
      5001
      # keep-sorted end
    ];

    allowedUDPPorts = [443];
  };

  services.traefik = {
    environmentFiles = ["${config.sops.templates."services/traefik/cloudflare.env".path}"];

    dynamicConfigOptions.http.middlewares.redirect-to-https.redirectScheme = {
      scheme = "https";

      permanent = true;
    };

    staticConfigOptions = {
      entryPoints = {
        # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=address\s*=\s*[^;]*?:(\d+)
        http.address = ":80";

        https = {
          address = ":443";

          http.tls.certResolver = "cloudflare";

          http3 = {};
        };

        dsm-http.address = ":5000";

        dsm-https.address = ":5001";
        # keep-sorted end
      };

      certificatesResolvers.cloudflare.acme = {
        email = "me@hilorioze.com";

        dnsChallenge.provider = "cloudflare";
      };
    };
  };
}
