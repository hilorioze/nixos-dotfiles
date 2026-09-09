final: _prev: {
  gnupg-pcsc-shared-reselect-fix = final.gnupg.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./pcsc-shared-reselect-fix.patch
      ];
  });
}
