{
  # https://github.com/RiverMatsumoto/oneplus-buds-pro-3-linux
  xdg.configFile."wireplumber/wireplumber.conf.d/51-oneplus-buds-pro-3.conf".text = builtins.toJSON {
    "monitor.bluez.rules" = [
      {
        matches = [
          {
            "device.description" = "OnePlus Buds Pro 3";
          }
        ];

        actions.update-props = {
          # keep-sorted start
          # "bluez5.enable-aac" = false;
          "bluez5.enable-hw-volume" = false;
          # "bluez5.enable-le-audio" = false;
          # "bluez5.enable-msbc" = false;
          # "bluez5.enable-sbc-xq" = true;
          # keep-sorted end
        };
      }
    ];
  };
}
