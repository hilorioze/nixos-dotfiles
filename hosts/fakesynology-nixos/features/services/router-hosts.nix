{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  services.prometheus.exporters.node.extraFlags = ["--collector.textfile.directory=/run/${config.systemd.services.router-hosts.serviceConfig.RuntimeDirectory}"];

  # export which lan hosts the router sees as active
  systemd.services.router-hosts = {
    description = "Router hosts metrics";

    startAt = "minutely";

    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";

      User = config.services.prometheus.exporters.node.user; # a dynamic user's preserved runtime directory sits under `/run/private`, which node-exporter can't enter

      RuntimeDirectory = "router-hosts";
      RuntimeDirectoryPreserve = true; # a oneshot loses its runtime directory when it exits; keep the metrics for node-exporter

      ExecStart = lib.getExe (pkgs.writeShellApplication {
        name = "router-hosts";

        runtimeInputs = with pkgs; [
          # keep-sorted start
          curl
          iproute2
          jq
          # keep-sorted end
        ];

        excludeShellChecks = (import ../../../../shared.nix).ignoredShellcheckRules;

        text = ''
          # the router serves a self-signed certificate
          curl --silent --show-error --fail --insecure https://$(ip --json route show default | jq --raw-output .[0].gateway)/api/v1/hosts | jq --raw-output '.[0].hosts.list[] | "router_host_active{name=\"\(.friendlyHostname)\",mac=\"\(.macaddress)\"} \(if .active then 1 else 0 end)"' >$RUNTIME_DIRECTORY/router-hosts.prom.tmp

          # don't let node-exporter read a half-written file
          mv $RUNTIME_DIRECTORY/router-hosts.prom.tmp $RUNTIME_DIRECTORY/router-hosts.prom
        '';
      });
    };
  };
}
