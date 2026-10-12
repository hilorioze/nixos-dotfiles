_final: prev: {
  unstablePkgs =
    prev.unstablePkgs
    // {
      gpu-screen-recorder-ui = prev.unstablePkgs.gpu-screen-recorder-ui.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [./unused-gpu-fix.patch];
      });
    };
}
