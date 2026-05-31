_final: prev: {
  kdePackages =
    prev.kdePackages
    // {
      spectacle = prev.kdePackages.spectacle.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [
            ./region-select-all.patch
          ];
      });
    };
}
