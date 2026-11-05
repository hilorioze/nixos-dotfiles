_final: prev: {
  unstablePkgs =
    prev.unstablePkgs
    // {
      gpu-screen-recorder = prev.unstablePkgs.gpu-screen-recorder.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [./drm-master-fix.patch];
      });
    };
}
