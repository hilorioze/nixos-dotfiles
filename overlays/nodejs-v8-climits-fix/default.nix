_final: prev: {
  nodejs-slim_26 = prev.nodejs-slim_26.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        (prev.fetchurl {
          url = "https://raw.githubusercontent.com/NixOS/nixpkgs/aa48d347080940b8a2b8d2f48228674e280a3514/pkgs/development/web/nodejs/memcpy-climits.patch";

          hash = "sha256-v2zY9vk3TWaGINyTCzPSiowarYuUuQUISUahqosRMRQ=";
        })
      ];
  });
}
