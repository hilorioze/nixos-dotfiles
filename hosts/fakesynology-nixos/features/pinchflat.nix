{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  users.users.${config.services.pinchflat.user}.extraGroups = [config.users.groups.media.name];

  services = {
    pinchflat = {
      enable = true;

      # TODO: replace with a real secret
      selfhosted = true; # allow startup without `SECRET_KEY_BASE`/`secretsFile` via pinchflat's public secret

      mediaDir = "/srv/media/library/youtube";
    };

    traefik.dynamicConfigOptions.http = {
      routers.pinchflat = {
        entryPoints = ["https"];
        rule = "Host(`pinchflat.${config.networking.fqdn}`)";

        service = "pinchflat";
      };

      services.pinchflat.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.pinchflat.port}";}];
    };
  };

  systemd.services.pinchflat.serviceConfig.UMask = lib.mkForce "0002";
}
