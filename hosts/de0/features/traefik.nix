{config, ...}: {
  imports = [../../common/features/traefik.nix];

  sops = {
    secrets."credentials/cloudflare/zones/hilorioze.com/dns01-token".sopsFile = ../secrets.yaml;

    templates."config/traefik.env".content = ''
      CF_DNS_API_TOKEN=${config.sops.placeholder."credentials/cloudflare/zones/hilorioze.com/dns01-token"}
    '';
  };

  services.traefik = {
    environmentFiles = ["${config.sops.templates."config/traefik.env".path}"];

    staticConfigOptions = {
      entryPoints.https.http.tls.certResolver = "cloudflare";

      certificatesResolvers.cloudflare.acme = {
        email = "me@hilorioze.com";

        storage = "${config.services.traefik.dataDir}/acme.json";

        dnsChallenge.provider = "cloudflare";
      };
    };
  };
}
