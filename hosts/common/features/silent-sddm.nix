{
  # keep-sorted start
  config,
  inputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.silent-sddm.nixosModules.default];

  programs.silentSDDM = {
    enable = true;

    package = pkgs.silent-sddm;

    backgrounds.wallpaper = config.stylix.image;

    settings = {
      LoginScreen = {
        background = builtins.baseNameOf config.stylix.image;
        use-background-color = false;
      };

      LockScreen = {
        background = builtins.baseNameOf config.stylix.image;
        use-background-color = false;
      };
    };
  };
}
