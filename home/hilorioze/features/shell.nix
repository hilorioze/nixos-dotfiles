{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.shellAliases = {
    c = "${lib.getExe' pkgs.ncurses "clear"}";
    l = "${lib.getExe' pkgs.coreutils "ls"} --color=auto -lah";

    ff = "${lib.getExe config.programs.fastfetch.package}";

    g = "${lib.getExe config.programs.git.package}";

    du = "${lib.getExe pkgs.devenv} update";

    nfc = "${lib.getExe pkgs.nix} flake check";
    nfl = "${lib.getExe pkgs.nix} flake lock";
    nfu = "${lib.getExe pkgs.nix} flake update";

    ns = "${lib.getExe config.programs.nh.package} os switch";
    nca = "${lib.getExe config.programs.nh.package} clean all";
  };
}
