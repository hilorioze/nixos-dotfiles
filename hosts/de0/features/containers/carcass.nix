{config, ...}: {
  sops.secrets."credentials/ghcr/hilorioze/pull/token" = {};

  virtualisation.oci-containers.containers.carcass = {
    image = "ghcr.io/hilorioze/carcass:main@sha256:dd05c84f3f3ecc72676c44303736d1597ec6a0e1a53a9731d01cdf4614242ca3";

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
