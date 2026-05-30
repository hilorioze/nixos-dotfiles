{config, ...}: {
  programs.nh = {
    enable = true;

    flake = "${config.home.homeDirectory}/projects/nixos-dotfiles";
  };
}
