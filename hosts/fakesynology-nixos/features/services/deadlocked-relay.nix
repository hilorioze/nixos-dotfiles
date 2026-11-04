{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  networking.firewall.allowedTCPPorts = [6346]; # deadlocked game-state feed ingest

  services.traefik.dynamicConfigOptions.http = {
    routers.deadlocked-relay = {
      entryPoints = ["https"];
      rule = "Host(`deadlocked-relay.${config.networking.fqdn}`)";

      service = "deadlocked-relay";
    };

    services.deadlocked-relay.loadBalancer.servers = [{url = "http://127.0.0.1:6347";}];
  };

  systemd.services.deadlocked-relay = {
    description = "Deadlocked web radar relay server";

    wantedBy = ["multi-user.target"];

    after = ["network-online.target"];

    wants = ["network-online.target"];

    serviceConfig = {
      DynamicUser = true;

      ExecStart = lib.getExe pkgs.deadlocked-relay;

      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
