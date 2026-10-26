{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}:
with lib; {
  options.programs.pear-desktop.package = mkPackageOption pkgs "pear-desktop" {};
}
