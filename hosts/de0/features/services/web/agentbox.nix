{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  services.traefik.dynamicConfigOptions = lib.mkMerge (
    [
      {
        tcp.serversTransports.agentbox.proxyProtocol = {}; # pass client addresses on; agentboxes trust the header only from their gateway
      }
    ]
    ++ lib.mapAttrsToList (name: machine: let
      # the agentbox's zone and every name under it
      hostRegexp = "^(.+\\.)?${lib.escapeRegex "${name}.${config.virtualisation.agentbox.domain}"}$";
    in {
      # https stays encrypted up to the agentbox, whose traefik holds the zone's certificate
      tcp = {
        routers."agentbox-${name}" = {
          entryPoints = ["https"];
          rule = "HostSNIRegexp(`${hostRegexp}`)";

          tls.passthrough = true;

          service = "agentbox-${name}";
        };

        services."agentbox-${name}".loadBalancer = {
          servers = [{address = "${machine.address}:443";}];

          serversTransport = "agentbox";
        };
      };

      # plain http goes to the agentbox too, which decides whether to redirect it
      http = {
        routers."agentbox-${name}-http" = {
          entryPoints = ["http"];
          rule = "HostRegexp(`${hostRegexp}`)";

          service = "agentbox-${name}-http";
        };

        services."agentbox-${name}-http".loadBalancer.servers = [{url = "http://${machine.address}";}];
      };
    })
    config.virtualisation.agentbox.machines
  );
}
