{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  systemd.user.services.steam-broker = {
    Install.WantedBy = ["default.target"];

    Unit.Description = "Xash3D FWGS Steam API broker";

    Service = {
      ExecStart = lib.getExe pkgs.steam-broker;

      Restart = "always";
      RestartSec = 2;
    };
  };
}
