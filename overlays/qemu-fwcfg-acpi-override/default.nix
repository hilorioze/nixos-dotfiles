_final: prev: {
  qemu = prev.qemu.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./fwcfg-acpi-override.patch
      ];
  });
}
