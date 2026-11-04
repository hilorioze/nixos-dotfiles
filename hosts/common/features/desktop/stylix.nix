{
  # keep-sorted start
  inputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.stylix.nixosModules.stylix];

  stylix = {
    enable = true;

    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    cursor = {
      package = pkgs.catppuccin-cursors.macchiatoBlue;
      name = "catppuccin-macchiato-blue-cursors";
      size = 24;
    };

    homeManagerIntegration.autoImport = false; # who the fuck came up with this?

    # the home-manager target already puts the theme in the users' data dir
    # this one patches it into gtksourceview itself and rebuilds everything that links it, inkscape included
    targets.gtksourceview.enable = false;
  };
}
