_final: prev: {
  kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
    kwin = kdePrev.kwin.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./force-activate-without-touch.patch];
    });
  });
}
