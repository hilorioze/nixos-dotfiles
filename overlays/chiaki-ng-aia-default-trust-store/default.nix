_final: prev: {
  unstablePkgs = prev.unstablePkgs.extend (_unstableFinal: unstablePrev: {
    chiaki-ng = unstablePrev.chiaki-ng.overrideAttrs (oldAttrs: {
      # nixpkgs' curl is built without a ca bundle path and falls back to openssl's default paths, so `CURLINFO_CAINFO` and `CURLINFO_CAPATH` are empty
      # the aia chain recovery for psn's push notification websocket builds its trust store and its repaired ca blob from those, so it falls back to openssl's defaults too
      patches =
        (oldAttrs.patches or [])
        ++ [./default-trust-store.patch];
    });
  });
}
