{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.file.".cli-proxy-api/config.yaml".source = (pkgs.formats.yaml {}).generate "cli-proxy-api-config.yaml" {
    host = "127.0.0.1";
    port = 8317;
  };

  systemd.user.services.cli-proxy-api = {
    Install.WantedBy = ["default.target"];

    Service = {
      ExecStart = "${lib.getExe pkgs.cli-proxy-api} -config %h/.cli-proxy-api/config.yaml";

      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
