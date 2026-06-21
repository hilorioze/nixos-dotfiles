{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  systemd.services.prometheus-podman-exporter = {
    wantedBy = ["multi-user.target"];

    after = ["podman.service"];

    environment.CONTAINERS_HELPER_BINARY_DIR = "${config.virtualisation.podman.package.helpersBin}/bin";

    path = [config.virtualisation.podman.package.helpersBin];

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.prometheus-podman-exporter} --collector.enhance-metrics";

      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
