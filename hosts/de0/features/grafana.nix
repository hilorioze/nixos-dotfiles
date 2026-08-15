{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets = {
    # keep-sorted start
    "services/grafana/admin-password".owner = config.systemd.services.grafana.serviceConfig.User;
    "services/grafana/secret-key".owner = config.systemd.services.grafana.serviceConfig.User;
    # keep-sorted end
  };

  services = {
    traefik.dynamicConfigOptions.http = {
      routers = {
        grafana-http = {
          entryPoints = ["http"];
          rule = "Host(`grafana.${config.networking.domain}`)";

          middlewares = ["redirect-to-https"];

          service = "noop@internal";
        };

        grafana = {
          entryPoints = ["https"];
          rule = "Host(`grafana.${config.networking.domain}`)";

          service = "grafana";
        };
      };

      services.grafana.loadBalancer.servers = [{url = "http://localhost:${toString config.services.grafana.settings.server.http_port}";}];
    };

    grafana = {
      enable = true;

      settings = {
        server.root_url = "https://grafana.${config.networking.domain}";

        security = {
          admin_user = "root";
          admin_email = "root@${config.networking.domain}";
          admin_password = "$__file{${config.sops.secrets."services/grafana/admin-password".path}}";

          secret_key = "$__file{${config.sops.secrets."services/grafana/secret-key".path}}";
        };
      };

      provision = {
        datasources.settings.datasources = [
          # keep-sorted start block=yes newline_separated=yes
          {
            name = "Loki";
            type = "loki";
            uid = "loki";

            url = "http://localhost:3100";
          }

          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus";

            url = "http://localhost:${toString config.services.prometheus.port}";

            isDefault = true;
          }
          # keep-sorted end
        ];

        dashboards.settings.providers = [
          {
            options.path = pkgs.linkFarm "grafana-dashboards" [
              # keep-sorted start block=yes newline_separated=yes
              {
                name = "loki-logs.json";

                path =
                  pkgs.runCommand "loki-logs.json" {
                    src = pkgs.fetchurl {
                      url = "https://grafana.com/api/dashboards/13639/revisions/2/download";

                      hash = "sha256-2dRUkooIA1E0Qshg58N+9duIW25iRruu1oW8ckBUNIA=";
                    };
                  } ''
                    sed 's/''${DS_LOKI}/loki/g' $src >$out
                  '';
              }

              {
                name = "node-exporter-full.json";

                path = pkgs.fetchurl {
                  url = "https://grafana.com/api/dashboards/1860/revisions/45/download";

                  hash = "sha256-GExrdAnzBtp1Ul13cvcZRbEM6iOtFrXXjEaY6g6lGYY=";
                };
              }

              {
                name = "synology-snmp.json";

                path =
                  pkgs.runCommand "synology-snmp.json" {
                    src = pkgs.fetchurl {
                      url = "https://grafana.com/api/dashboards/18643/revisions/1/download";

                      hash = "sha256-ip62qmYpycKukQfR/pGm9F/di0AIjUrDN9Vk7AdYb+Q=";
                    };
                  } ''
                    sed 's/''${DS_PROMETHEUS}/prometheus/g' $src >$out
                  '';
              }
              # keep-sorted end
            ];
          }
        ];
      };
    };
  };
}
