_final: prev: {
  kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
    plasma-pa = kdePrev.plasma-pa.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./volume-step-snap.patch];
    });
  });
}
