{config, ...}: {
  imports = [../../common/features/traefik.nix];

  sops = {
    secrets."credentials/cloudflare/zones/hilorioze.com/dns01" = {};

    templates."services/traefik/cloudflare.env".content = ''
      CF_DNS_API_TOKEN=${config.sops.placeholder."credentials/cloudflare/zones/hilorioze.com/dns01"}
    '';
  };

  services.traefik = {
    environmentFiles = ["${config.sops.templates."services/traefik/cloudflare.env".path}"];

    staticConfigOptions = {
      entryPoints.https = {
        http.tls.certResolver = "cloudflare";

        transport.respondingTimeouts.idleTimeout = "1m"; # default HTTP/3 30s is too short for lampa on a bad connection
      };

      certificatesResolvers.cloudflare.acme = {
        email = "me@hilorioze.com";
        storage = "${config.services.traefik.dataDir}/acme.json";
        dnsChallenge.provider = "cloudflare";
      };
    };
  };
}
