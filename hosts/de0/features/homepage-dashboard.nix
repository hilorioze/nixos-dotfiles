{
  # keep-sorted start
  config,
  outputs,
  # keep-sorted end
  ...
}: {
  services = {
    traefik.dynamicConfigOptions.http = {
      routers.homepage-dashboard = {
        entryPoints = ["http" "https"];
        rule = "Host(`dashboard.${config.networking.domain}`)";

        service = "homepage-dashboard";
      };

      services.homepage-dashboard.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.homepage-dashboard.listenPort}";}];
    };

    homepage-dashboard = {
      enable = true;

      allowedHosts = "dashboard.${config.networking.domain}";

      services = let
        de0Host = outputs.nixosConfigurations.de0.config.networking.fqdn;

        mkService = name: icon: href: {
          ${name} = {
            inherit href icon;
          };
        };

        mkTraefikDashboardService = nixosConfiguration: let
          inherit (nixosConfiguration.config.networking) fqdn hostName;
        in
          mkService "Traefik (${hostName})" "traefik.svg" "https://traefik.${fqdn}";
      in [
        {
          Infrastructure = [
            # keep-sorted start block=yes newline_separated=yes case=no by_regex=(?:mkService\s+"|\(mk)([^"\s]+)
            (mkService "Gatus" "gatus.svg" "https://status.${config.networking.domain}")

            (mkService "Grafana" "grafana.svg" outputs.nixosConfigurations.de0.config.services.grafana.settings.server.root_url)

            (mkService "Synology DSM" "synology.svg" "https://fakesynology.${config.networking.domain}")

            (mkTraefikDashboardService outputs.nixosConfigurations.de0)

            (mkTraefikDashboardService outputs.nixosConfigurations.fakesynology-nixos)

            (mkTraefikDashboardService outputs.nixosConfigurations.hel0)
            # keep-sorted end
          ];
        }

        {
          Services = [
            # keep-sorted start block=yes newline_separated=yes case=no by_regex=mkService\s+"([^"]+)
            (mkService "ArchiSteamFarm" "archisteamfarm.png" "https://archisteamfarm.${de0Host}")

            (mkService "Twitch Drops Miner (caligula)" "twitch.svg" "https://twitch-drops-miner-caligula.${de0Host}")

            (mkService "Twitch Drops Miner (hilorioze)" "twitch.svg" "https://twitch-drops-miner-hilorioze.${de0Host}")

            (mkService "Twitch Drops Miner (zikkk)" "twitch.svg" "https://twitch-drops-miner-zikkk.${de0Host}")
            # keep-sorted end
          ];
        }
      ];

      settings = {
        title = "hilorioze";

        layout = [
          {
            Infrastructure = {
              style = "row";

              columns = 3;
            };
          }

          {
            Services = {
              style = "row";

              columns = 3;
            };
          }
        ];
      };

      widgets = [
        {
          search.provider = "duckduckgo";
        }
      ];
    };
  };
}
