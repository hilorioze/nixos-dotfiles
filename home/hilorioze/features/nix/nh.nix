{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  programs.nh = {
    enable = true;

    flake = "${config.home.homeDirectory}/projects/nixos-dotfiles";
  };

  home.shellAliases = {
    ns = "${lib.getExe config.programs.nh.package} os switch";
    nca = "${lib.getExe config.programs.nh.package} clean all";
  };
}
