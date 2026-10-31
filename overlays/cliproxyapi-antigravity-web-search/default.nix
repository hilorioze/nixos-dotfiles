_final: prev: {
  unstablePkgs =
    prev.unstablePkgs
    // {
      cliproxyapi = prev.unstablePkgs.cliproxyapi.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [./antigravity-web-search.patch];
      });
    };
}
