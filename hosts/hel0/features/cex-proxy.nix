{config, ...}: let
  dsmHttpPort = 5000;
  dsmHttpsPort = 5001;
in {
  networking.firewall.allowedTCPPorts = [dsmHttpPort dsmHttpsPort];

  services.traefik = {
    staticConfigOptions.entryPoints = {
      cex-http.address = ":${toString dsmHttpPort}";
      cex-https.address = ":${toString dsmHttpsPort}";
    };

    dynamicConfigOptions = {
      http = {
        routers = {
          cex-entrypoint = {
            entryPoints = ["http"];
            rule = "Host(`cex.${config.networking.domain}`)";

            service = "cex-entrypoint";
          };

          cex = {
            entryPoints = ["cex-http"];
            rule = "Host(`cex.${config.networking.domain}`)";

            service = "cex";
          };
        };

        services = {
          cex-entrypoint.loadBalancer.servers = [{url = "http://cex.hilorioze.com";}];

          cex.loadBalancer.servers = [{url = "http://cex.hilorioze.com:${toString dsmHttpPort}";}];
        };
      };

      tcp = {
        routers = {
          cex-entrypoint = {
            entryPoints = ["https"];
            rule = "HostSNI(`cex.${config.networking.domain}`)";

            tls.passthrough = true;
            service = "cex-entrypoint";
          };

          cex = {
            entryPoints = ["cex-https"];
            rule = "HostSNI(`cex.${config.networking.domain}`)";

            tls.passthrough = true;
            service = "cex";
          };
        };

        services = {
          cex-entrypoint.loadBalancer.servers = [{address = "cex.hilorioze.com:443";}];

          cex.loadBalancer.servers = [{address = "cex.hilorioze.com:${toString dsmHttpsPort}";}];
        };
      };
    };
  };
}
