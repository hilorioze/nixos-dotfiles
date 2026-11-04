{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.shellAliases = {
    c = lib.getExe' pkgs.ncurses "clear";
    l = "${lib.getExe' pkgs.coreutils "ls"} --format=long --all --human-readable --color=auto";

    ff = lib.getExe config.programs.fastfetch.package;

    nfc = "${lib.getExe pkgs.nix} flake check";
    nfl = "${lib.getExe pkgs.nix} flake lock";
    nfu = "${lib.getExe pkgs.nix} flake update";
  };
}
