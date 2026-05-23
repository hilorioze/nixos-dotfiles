{
  programs.vesktop = {
    enable = true;

    vencord = {
      useSystem = true;

      settings = {
        autoUpdate = false;
        autoUpdateNotification = false;

        hardwareVideoAcceleration = true;
      };
    };
  };

  xdg.configFile."vesktop/state.json".text = builtins.toJSON {
    firstLaunch = false;
  };
}
