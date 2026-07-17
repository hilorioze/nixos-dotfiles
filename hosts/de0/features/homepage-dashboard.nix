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
        hel0Host = outputs.nixosConfigurations.hel0.config.networking.fqdn;

        mkService = name: icon: href: {
          ${name} = {
            inherit href icon;
          };
        };
      in [
        {
          Infrastructure = [
            # keep-sorted start block=yes newline_separated=yes case=no by_regex=mkService\s+"([^"]+)
            (mkService "Gatus" "gatus.svg" "https://status.${config.networking.domain}")

            (mkService "Grafana" "grafana.svg" outputs.nixosConfigurations.de0.config.services.grafana.settings.server.root_url)

            (mkService "Synology DSM" "synology.svg" "https://fakesynology.${config.networking.domain}")
            # keep-sorted end
          ];
        }

        {
          Services = [
            # keep-sorted start block=yes newline_separated=yes case=no by_regex=mkService\s+"([^"]+)
            (mkService "ArchiSteamFarm" "archisteamfarm.png" "https://archisteamfarm.${hel0Host}")

            (mkService "Twitch Drops Miner (caligula)" "twitch.svg" "https://twitch-drops-miner-caligula.${hel0Host}")

            (mkService "Twitch Drops Miner (hilorioze)" "twitch.svg" "https://twitch-drops-miner-hilorioze.${hel0Host}")

            (mkService "Twitch Drops Miner (zikkk)" "twitch.svg" "https://twitch-drops-miner-zikkk.${hel0Host}")
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
