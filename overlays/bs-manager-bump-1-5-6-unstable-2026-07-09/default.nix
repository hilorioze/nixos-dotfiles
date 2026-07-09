final: prev: {
  bs-manager = prev.bs-manager.overrideAttrs (finalAttrs: oldAttrs: {
    version = "1.5.6-unstable-2026-07-09";

    src = oldAttrs.src.override {
      tag = null;
      rev = "b5b91260fa57cb9323d1bf39a9b23771df88a472";
      hash = "sha256-AAME/HxGHAq0B83zPU9jWAYY17B0XfNMoRfB2BJFFik=";
    };

    extraNpmDeps = final.fetchNpmDeps {
      name = "bs-manager-${finalAttrs.version}-extra-npm-deps";

      inherit (finalAttrs) src;
      sourceRoot = "${finalAttrs.src.name}/release/app";

      hash = "sha256-jE/M22QQzuTS0zgcB+tLEL8Ey61HE8MP7H1MTX060gY=";
    };
  });
}
