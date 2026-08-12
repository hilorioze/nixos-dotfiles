_final: prev: {
  gnupg = prev.gnupg.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./pcsc-shared-reselect-fix.patch
      ];
  });
}
