{config, ...}: {
  xdg.configFile = {
    "openrazer/persistence.conf".text = ''
      [PM2112F41300274]
      backlight_effect = static
      backlight_colors = 0 71 255 0 71 255 0 71 255
    '';

    "systemd/user/openrazer-daemon.service.d/overrides.conf".text = ''
      [Unit]
      X-Restart-Triggers=${config.xdg.configFile."openrazer/persistence.conf".source}
    '';
  };
}
