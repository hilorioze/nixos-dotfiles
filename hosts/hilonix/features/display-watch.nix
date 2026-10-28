{
  lib,
  pkgs,
  ...
}: let
  displayWatch =
    pkgs.writers.writePython3 "display-watch" {
      flakeIgnore = (import ../../../shared.nix).ignoredFlake8Rules;
    }
    # python
    ''
      import argparse
      import pathlib
      import shlex
      import subprocess
      import time

      DRM_PATH: pathlib.Path = pathlib.Path("/sys/class/drm")

      POLL_INTERVAL: float = 1
      DISPLAYS_OFF_DELAY: float = 5


      def parse_arguments() -> argparse.Namespace:
          parser: argparse.ArgumentParser = argparse.ArgumentParser()
          parser.add_argument("--displays-on-command", type=shlex.split, required=True)
          parser.add_argument("--displays-off-command", type=shlex.split, required=True)

          arguments: argparse.Namespace = parser.parse_args()

          return arguments


      def is_connector_on(connector: pathlib.Path) -> bool:
          status: str = (connector / "status").read_text().strip()
          dpms: str = (connector / "dpms").read_text().strip()

          return status == "connected" and dpms == "On"


      def are_displays_on() -> bool:
          return any(is_connector_on(connector) for connector in DRM_PATH.glob("card*-*"))


      def watch_displays(*, displays_on_command: list[str], displays_off_command: list[str]) -> None:
          reported_displays_on: bool | None = None
          displays_off_since: float | None = None

          while True:
              displays_on: bool = are_displays_on()

              if displays_on:
                  displays_off_since = None
              elif displays_off_since is None:
                  displays_off_since = time.monotonic()

              # outputs go off for a moment while one compositor hands them over to the next, e.g. on login
              settled: bool = displays_on or time.monotonic() - displays_off_since >= DISPLAYS_OFF_DELAY

              if settled and displays_on != reported_displays_on:
                  subprocess.run(displays_on_command if displays_on else displays_off_command)

                  reported_displays_on = displays_on

              time.sleep(POLL_INTERVAL)


      def main() -> None:
          arguments: argparse.Namespace = parse_arguments()

          watch_displays(displays_on_command=arguments.displays_on_command, displays_off_command=arguments.displays_off_command)


      if __name__ == "__main__":
          main()
    '';

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
