{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  users.users.${config.services.sonarr.user}.extraGroups = [config.users.groups.media.name];

  services = {
    sonarr.enable = true;

    traefik.dynamicConfigOptions.http = {
      routers.sonarr = {
        entryPoints = ["https"];
        rule = "Host(`sonarr.${config.networking.fqdn}`)";

        service = "sonarr";
      };

      services.sonarr.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.sonarr.settings.server.port}";}];
    };
  };

  systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
}
