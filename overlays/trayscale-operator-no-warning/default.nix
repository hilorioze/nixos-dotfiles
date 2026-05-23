_final: prev: {
  trayscale = prev.trayscale.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./operator-no-warning.patch
      ];
  });
}
