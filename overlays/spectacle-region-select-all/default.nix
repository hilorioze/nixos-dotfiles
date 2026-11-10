_final: prev: {
  kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
    spectacle = kdePrev.spectacle.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./region-select-all.patch];
    });
  });
}
