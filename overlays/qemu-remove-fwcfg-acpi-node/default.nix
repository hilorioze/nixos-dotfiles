_final: prev: {
  qemu = prev.qemu.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./remove-fwcfg-acpi-node.patch
      ];
  });
}
