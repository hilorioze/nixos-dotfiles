_final: prev: {
  kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
    konsole = kdePrev.konsole.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./wayland-tab-dnd-fix.patch];
    });
  });
}
