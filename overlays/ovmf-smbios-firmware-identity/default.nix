_final: prev: {
  OVMF = prev.OVMF.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./smbios-firmware-identity.patch
      ];
  });
}
