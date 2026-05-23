{inputs, ...}: {
  imports = [inputs.mt7927-nixos.nixosModules.default];

  hardware.mediatek-mt7927.enable = true;
}
