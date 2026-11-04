{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  port = 4000;
in {
  networking.firewall.allowedTCPPorts = [port];

  systemd.services.mud = {
    description = "Gull Rock MUD server";

    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.mud} --host 0.0.0.0 --port ${toString port}";

      DynamicUser = true;

      Restart = "always";
      RestartSec = 2;
    };
  };
}
