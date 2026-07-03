{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  users.users.${config.services.jellyfin.user}.extraGroups = [config.users.groups.media.name];

  services = {
    jellyfin.enable = true;

    traefik.dynamicConfigOptions.http = {
      routers.jellyfin = {
        entryPoints = ["https"];
        rule = "Host(`jellyfin.${config.networking.fqdn}`)";

        service = "jellyfin";
      };

      services.jellyfin.loadBalancer.servers = [{url = "http://127.0.0.1:8096";}];
    };
  };

  systemd.services.jellyfin.serviceConfig.UMask = lib.mkForce "0002";
}
