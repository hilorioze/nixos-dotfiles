_final: prev: {
  unstablePkgs = prev.unstablePkgs.extend (_unstableFinal: unstablePrev: {
    cliproxyapi = unstablePrev.cliproxyapi.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./system-instruction-as-user.patch];
    });
  });
}
