{
  # keep-sorted start
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [inputs.stylix.homeModules.stylix];

  stylix = {
    enable = true;

    targets.qt.standardDialogs = lib.mkDefault "xdgdesktopportal";
  };
}
