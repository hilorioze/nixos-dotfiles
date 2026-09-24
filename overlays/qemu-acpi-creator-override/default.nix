_final: prev: {
  qemu = prev.qemu.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./acpi-creator-override.patch
      ];
  });
}
