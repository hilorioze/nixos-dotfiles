_final: prev: {
  kdePackages =
    prev.kdePackages
    // {
      konsole = prev.kdePackages.konsole.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [./wayland-tab-dnd-fix.patch];
      });
    };
}
