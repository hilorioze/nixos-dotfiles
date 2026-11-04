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

  # load the theme by its store path: qt keys its qml cache by source path and mtime, and both stay the same under `/run/current-system` when the theme changes
  services.displayManager.sddm.settings.Theme.ThemeDir = "${config.programs.silentSDDM.package'}/share/sddm/themes";
}
