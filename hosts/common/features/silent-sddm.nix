{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.silent-sddm.nixosModules.default];

  programs.silentSDDM = {
    enable = true;

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
