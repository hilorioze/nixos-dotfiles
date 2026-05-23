{lib, ...}: {
  imports = [../../common/features/nix-ld.nix];

  programs.nix-ld.libraries = lib.mkForce []; # disable all libraries, let nix-alien handle them, we don't use nix-ld directly
}
