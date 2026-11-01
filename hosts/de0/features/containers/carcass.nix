{config, ...}: {
  sops.secrets."credentials/ghcr/hilorioze/pull/token" = {};

  virtualisation.oci-containers.containers.carcass = {
    image = "ghcr.io/hilorioze/carcass:main@sha256:2ee3d45172e9e1dffb37fd4f4054b518f92ac12700e891ff431c19e47bf3d497";

    login = {
      registry = "ghcr.io";

      username = "hilorioze";
      passwordFile = config.sops.secrets."credentials/ghcr/hilorioze/pull/token".path;
    };

    labels = {
      "traefik.enable" = "true";

      "traefik.http.routers.carcass-http.entryPoints" = "http";
      "traefik.http.routers.carcass-http.rule" = "Host(`carcass.${config.networking.domain}`)";
      "traefik.http.routers.carcass-http.middlewares" = "redirect-to-https@file";
      "traefik.http.routers.carcass-http.service" = "noop@internal";

      "traefik.http.routers.carcass.entryPoints" = "https";
      "traefik.http.routers.carcass.rule" = "Host(`carcass.${config.networking.domain}`)";
      "traefik.http.routers.carcass.middlewares" = "oidc-login@file";
      "traefik.http.routers.carcass.service" = "carcass";

      "traefik.http.services.carcass.loadBalancer.server.port" = "4180";
    };

    volumes = ["carcass-data:/data"];

    extraOptions = ["--init"]; # forward stop signals to node
  };
}
