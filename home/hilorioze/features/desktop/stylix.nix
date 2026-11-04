{
  # keep-sorted start
  inputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.stylix.homeModules.stylix];

  stylix = {
    enable = true;

    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    opacity.popups = 0.5;

    targets.qt.standardDialogs = "xdgdesktopportal";
  };
}
