{
  # keep-sorted start
  config,
  # keep-sorted end
  ...
}: {
  services.traefik.dynamicConfigOptions.http = {
    routers.whoami = {
      entryPoints = ["http" "https"];
      rule = "Host(`whoami.${config.networking.fqdn}`)";
      service = "whoami";
    };
    services.whoami.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.whoami.port}";}];
  };

  services.whoami.enable = true;
}
