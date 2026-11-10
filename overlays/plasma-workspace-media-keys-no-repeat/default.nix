_final: prev: {
  kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
    plasma-workspace = kdePrev.plasma-workspace.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./media-keys-no-repeat.patch];
    });
  });
}
