_final: prev: {
  unstablePkgs = prev.unstablePkgs.extend (_unstableFinal: unstablePrev: {
    gpu-screen-recorder-ui = unstablePrev.gpu-screen-recorder-ui.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./unused-gpu-fix.patch];
    });
  });
}
