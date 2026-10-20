{inputs, ...}: {
  imports = [inputs.stylix.nixosModules.stylix];

  stylix = {
    enable = true;

    homeManagerIntegration.autoImport = false; # who the fuck came up with this?

    # the home-manager target already puts the theme in the users' data dir
    # this one patches it into gtksourceview itself and rebuilds everything that links it, inkscape included
    targets.gtksourceview.enable = false;
  };
}
