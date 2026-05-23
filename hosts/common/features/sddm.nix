{config, ...}: {
  environment.systemPackages = [config.stylix.cursor.package];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;

    settings.Theme = {
      CursorTheme = config.stylix.cursor.name;
      CursorSize = toString config.stylix.cursor.size;
    };
  };
}
