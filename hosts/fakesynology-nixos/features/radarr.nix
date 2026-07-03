{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  users.users.${config.services.radarr.user}.extraGroups = [config.users.groups.media.name];

  services = {
    radarr.enable = true;

    traefik.dynamicConfigOptions.http = {
      routers.radarr = {
        entryPoints = ["https"];
        rule = "Host(`radarr.${config.networking.fqdn}`)";

        service = "radarr";
      };

      services.radarr.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.radarr.settings.server.port}";}];
    };
  };

  systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";
}
