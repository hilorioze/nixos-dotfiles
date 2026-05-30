{inputs, ...}: {
  imports = [inputs.stylix.nixosModules.stylix];

  stylix = {
    enable = true;

    homeManagerIntegration.autoImport = false; # who the fuck came up with this?
  };
}
