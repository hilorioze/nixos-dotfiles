{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets."credentials/cloudflare/zones/hilorioze.com/dns01-token" = {};

    templates."services/traefik/cloudflare.env".content = "CF_DNS_API_TOKEN=${config.sops.placeholder."credentials/cloudflare/zones/hilorioze.com/dns01-token"}";
  };

  networking.firewall = {
    allowedTCPPorts = [
      # keep-sorted start numeric=yes
      80
      443
      # keep-sorted end
    ];

    allowedUDPPorts = [443];
  };

  services.traefik = {
    enable = true;

    environmentFiles = [config.sops.templates."services/traefik/cloudflare.env".path];

    dynamicConfigOptions.http.middlewares.redirect-to-https.redirectScheme = {
      scheme = "https";

      permanent = true;
    };

    staticConfigOptions = {
      accessLog = {};

      global = {
        checkNewVersion = false;

        sendAnonymousUsage = false;
      };

      entryPoints = {
        # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=address\s*=\s*[^;]*?:(\d+)
        http.address = ":80";

        https = {
          address = ":443";

          http.tls.certResolver = "cloudflare";

          http3 = {};

          forwardedHeaders.trustedIPs = let
            readLinesFromURL = url: sha256:
            # use `builtins.fetchurl` because `pkgs.fetchurl` breaks cross-system eval
              lib.splitString "\n" (builtins.readFile (builtins.fetchurl {
                inherit url;

                inherit sha256;
              }));
          in
            # trust `X-Forwarded-*` and `X-Real-IP` headers from cloudflare edge IPs
            readLinesFromURL "https://www.cloudflare.com/ips-v4" "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns="
            ++ readLinesFromURL "https://www.cloudflare.com/ips-v6" "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
        };
        # keep-sorted end
      };

      certificatesResolvers.cloudflare.acme = {
        email = "hilorioze@hilorioze.com";

        dnsChallenge = {
          provider = "cloudflare";

          # bypass local DNS caching during ACME propagation checks
          resolvers = [
            "1.1.1.1:53"
            "1.0.0.1:53"
          ];
        };
      };
    };
  };
}
