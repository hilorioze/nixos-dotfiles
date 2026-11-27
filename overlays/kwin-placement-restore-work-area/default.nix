_final: prev: {
  kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
    kwin = kdePrev.kwin.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./placement-restore-work-area.patch];
    });
  });
}
