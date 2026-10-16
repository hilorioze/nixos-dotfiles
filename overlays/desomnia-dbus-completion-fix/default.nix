_final: prev: {
  desomnia = prev.desomnia.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [./fix-dbus-completion.patch];
  });
}
