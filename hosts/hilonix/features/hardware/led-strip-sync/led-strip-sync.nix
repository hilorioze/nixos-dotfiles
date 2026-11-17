{
  lib,
  pkgs,
  ...
}: let
  ledStripControl = pkgs.unstablePkgs.writers.writePython3 "led-strip-control" {
    libraries = [pkgs.unstablePkgs.python3Packages.bleak]; # bleak before 3.0.0 closes the bus when the strip drops the connection, failing the disconnect with `EOFError`

    doCheck = false; # treefmt lints the script with ruff
  } (builtins.readFile ./led-strip-control.py);

  ledStripAddress = "24:10:31:04:24:F1";

  ledStripLock = "/run/led-strip-control.lock";

  ledStripColor = "00ffff";
  ledStripBrightness = 620; # app's range is 620..4095, the strip itself accepts 0..4095 and is still lit at 0

  ledStripControlCommand = "${ledStripControl} --address ${ledStripAddress} --lock ${ledStripLock}";

  ledStripTurnOnCommand = "${ledStripControlCommand} on --color ${ledStripColor} --brightness ${toString ledStripBrightness}";
  ledStripTurnOffCommand = "${ledStripControlCommand} off";

  ledStripService.serviceConfig.Type = "oneshot";
in {
  systemd = {
    tmpfiles.rules = ["f ${ledStripLock} 0644 root root -"];

    services = {
      led-strip-power-sync = lib.mkMerge [
        ledStripService

        {
          description = "LED strip follows the power state";

          wantedBy = ["multi-user.target"];

          after = ["bluetooth.service"]; # also stops it before bluetooth goes down on shutdown

          serviceConfig = {
            RemainAfterExit = true;

            ExecStart = ledStripTurnOnCommand;
            ExecStop = ledStripTurnOffCommand;
          };
        }
      ];

      led-strip-display-on = lib.mkMerge [
        ledStripService

        {
          description = "LED strip turns on with the displays";

          wantedBy = ["displays-on.target"];

          after = ["led-strip-power-sync.service"]; # on shutdown a turn-on that is still running is stopped before the strip is turned off

          serviceConfig.ExecStart = ledStripTurnOnCommand;
        }
      ];

      led-strip-display-off = lib.mkMerge [
        ledStripService

        {
          description = "LED strip turns off with the displays";

          wantedBy = ["displays-off.target"];

          after = ["led-strip-display-on.service"]; # a turn-on that is still running finishes first, so the strip ends up off

          serviceConfig.ExecStart = ledStripTurnOffCommand;
        }
      ];
    };
  };
}
