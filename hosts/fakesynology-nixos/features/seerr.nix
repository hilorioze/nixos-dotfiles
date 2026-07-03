{config, ...}: {
  services = {
    seerr.enable = true;

    traefik.dynamicConfigOptions.http = {
      routers.seerr = {
        entryPoints = ["https"];
        rule = "Host(`seerr.${config.networking.fqdn}`)";

        service = "seerr";
      };

      services.seerr.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.seerr.port}";}];
    };
  };
}
