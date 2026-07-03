{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  users.users.${config.services.bazarr.user}.extraGroups = [config.users.groups.media.name];

  services = {
    bazarr.enable = true;

    traefik.dynamicConfigOptions.http = {
      routers.bazarr = {
        entryPoints = ["https"];
        rule = "Host(`bazarr.${config.networking.fqdn}`)";

        service = "bazarr";
      };

      services.bazarr.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.bazarr.listenPort}";}];
    };
  };

  systemd.services.bazarr.serviceConfig.UMask = lib.mkForce "0002";
}
