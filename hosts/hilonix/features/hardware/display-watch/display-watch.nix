{
  lib,
  pkgs,
  ...
}: let
  displayWatch = pkgs.writers.writePython3 "display-watch" {
    flakeIgnore = (import ../../../../../shared.nix).ignoredFlake8Rules;
  } (builtins.readFile ./display-watch.py);

  systemctl = lib.getExe' pkgs.systemd "systemctl";

  displaysTarget.unitConfig.X-OnlyManualStart = true; # switches leave these targets alone; otherwise each one reruns the lighting units they want, and a failed bluetooth write fails the whole switch
in {
  systemd = {
    targets = {
      displays-on = lib.mkMerge [
        displaysTarget

        {description = "Displays on";}
      ];

      displays-off = lib.mkMerge [
        displaysTarget

        {
          description = "Displays off";

          wantedBy = ["sleep.target"]; # powerdevil turns the displays off only right before sleep, too late for the watcher

          before = ["sleep.target"];

          conflicts = ["displays-on.target"];
          after = ["display-watch-sleep.service"]; # the watcher is stopped first, so it can't start the turn-ons again in between
        }
      ];
    };

    services = {
      display-watch = {
        description = "Display state watcher";

        wantedBy = ["multi-user.target"];

        serviceConfig = {
          ExecStart = "${displayWatch} --displays-on-command '${systemctl} start --no-block displays-on.target' --displays-off-command '${systemctl} start --no-block displays-off.target'";

          Restart = "on-failure";
        };
      };

      display-watch-sleep = {
        description = "Display state watcher stops for sleep";

        wantedBy = ["sleep.target"];

        before = ["sleep.target"];

        # powerdevil turns the displays off right before sleep, and the units the watcher starts then would run across it
        conflicts = ["display-watch.service"];
        after = ["display-watch.service"]; # without an ordering sleep goes on while the watcher is still running

        unitConfig.StopWhenUnneeded = true; # runs `ExecStop` once `sleep.target` is stopped on resume

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;

          ExecStop = "${systemctl} start --no-block display-watch.service"; # on start the watcher reports the current state, which also starts the units of an already active target again
        };
      };
    };
  };
}
