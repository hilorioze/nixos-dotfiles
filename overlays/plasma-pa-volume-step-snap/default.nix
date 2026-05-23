_final: prev: {
  kdePackages =
    prev.kdePackages
    // {
      plasma-pa = prev.kdePackages.plasma-pa.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [
            ./volume-step-snap.patch
          ];
      });
    };
}
