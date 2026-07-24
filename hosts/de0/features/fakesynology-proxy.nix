{config, ...}: let
  dsmHttpPort = 5000;
  dsmHttpsPort = 5001;
in {
  networking.firewall.allowedTCPPorts = [dsmHttpPort dsmHttpsPort];

  services.traefik = {
    staticConfigOptions.entryPoints = {
      fakesynology-http.address = ":${toString dsmHttpPort}";
      fakesynology-https.address = ":${toString dsmHttpsPort}";
    };

    dynamicConfigOptions = {
      http = {
        routers = {
          fakesynology-entrypoint = {
            entryPoints = ["http"];
            rule = "Host(`fakesynology.${config.networking.domain}`)";

            service = "fakesynology-entrypoint";
          };

          fakesynology = {
            entryPoints = ["fakesynology-http"];
            rule = "Host(`fakesynology.${config.networking.domain}`)";

            service = "fakesynology";
          };
        };

        services = {
          fakesynology-entrypoint.loadBalancer.servers = [{url = "http://fakesynology.hilorioze.com";}];

          fakesynology.loadBalancer.servers = [{url = "http://fakesynology.hilorioze.com:${toString dsmHttpPort}";}];
        };
      };

      tcp = {
        routers = {
          fakesynology-entrypoint = {
            entryPoints = ["https"];
            rule = "HostSNI(`fakesynology.${config.networking.domain}`)";

            tls.passthrough = true;
            service = "fakesynology-entrypoint";
          };

          fakesynology = {
            entryPoints = ["fakesynology-https"];
            rule = "HostSNI(`fakesynology.${config.networking.domain}`)";

            tls.passthrough = true;
            service = "fakesynology";
          };
        };

        services = {
          fakesynology-entrypoint.loadBalancer.servers = [{address = "fakesynology.hilorioze.com:443";}];

          fakesynology.loadBalancer.servers = [{address = "fakesynology.hilorioze.com:${toString dsmHttpsPort}";}];
        };
      };
    };
  };
}
