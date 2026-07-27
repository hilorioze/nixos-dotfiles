{inputs, ...}: {
  imports = [inputs.lazyvim-nix.homeManagerModules.default];

  programs.lazyvim.enable = true;
}
