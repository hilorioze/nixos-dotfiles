_final: prev: {
  wivrn = prev.wivrn.overrideAttrs (finalAttrs: oldAttrs: {
    version = "26.9";

    src = oldAttrs.src.overrideAttrs (_: {
      rev = "v${finalAttrs.version}";
      hash = "sha256-/kXgbku/4EeYY5YTwtY71csgxOP8bRACLqOvKXolg5g=";
    });

    monado = oldAttrs.monado.overrideAttrs (oldMonadoAttrs: {
      src = oldMonadoAttrs.src.overrideAttrs (_: {
        rev = "f037264d23e2472a444a157370647fcd601ed81b";
        hash = "sha256-exHbecudAy57szL7kut7/fBYCoekEs3riZzhMtFWS/c=";
      });
    });
  });
}
