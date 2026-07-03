{config, ...}: {
  services = {
    prowlarr.enable = true;

    traefik.dynamicConfigOptions.http = {
      routers.prowlarr = {
        entryPoints = ["https"];
        rule = "Host(`prowlarr.${config.networking.fqdn}`)";

        service = "prowlarr";
      };

      services.prowlarr.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.prowlarr.settings.server.port}";}];
    };
  };
}
