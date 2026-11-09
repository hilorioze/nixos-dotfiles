_final: prev: {
  unstablePkgs = prev.unstablePkgs.extend (_unstableFinal: unstablePrev: {
    gpu-screen-recorder = unstablePrev.gpu-screen-recorder.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./drm-master-fix.patch];
    });
  });
}
