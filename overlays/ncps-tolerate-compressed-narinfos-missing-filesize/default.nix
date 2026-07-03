_final: prev: {
  ncps = prev.ncps.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./tolerate-compressed-narinfos-missing-filesize.patch
      ];
  });
}
