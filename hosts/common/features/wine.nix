{
  # keep-sorted start
  inputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.nix-gaming.nixosModules.wine];

  programs.wine = {
    enable = true;

    package = pkgs.wine-tkg;

    binfmt = true;

    ntsync = true;
  };
}
