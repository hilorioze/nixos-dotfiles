{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  # the buds have 17 volume levels, so their swipes land between the steps of the volume keys
  systemd.user.services.oneplus-buds-pro-3-volume-snap = {
    Install.WantedBy = ["graphical-session.target"];

    Unit = {
      Description = "OnePlus Buds Pro 3 volume snapping";

      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${lib.getExe pkgs.bluetooth-volume-snap} --address 40:72:18:C8:3E:48 --step ${toString config.programs.plasma.configFile.plasmaparc.General.VolumeStep.value}";

      Restart = "on-failure"; # bluetoothd may not be up yet when the session starts
    };
  };
}
