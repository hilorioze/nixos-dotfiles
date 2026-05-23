{
  # keep-sorted start
  config,
  # keep-sorted end
  ...
}: {
  programs.nh = {
    enable = true;

    flake = "${config.home.homeDirectory}/projects/nixos-dotfiles";
  };
}
