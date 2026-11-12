_final: prev: {
  unstablePkgs = prev.unstablePkgs.extend (_unstableFinal: unstablePrev: {
    niks3 = unstablePrev.niks3.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [./upstream-cache-filter.patch];
    });
  });
}
