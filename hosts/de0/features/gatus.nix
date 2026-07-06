{
  # keep-sorted start
  config,
  lib,
  outputs,
  # keep-sorted end
  ...
}: {
  services = {
    traefik.dynamicConfigOptions.http = {
      routers.gatus = {
        entryPoints = ["http" "https"];
        rule = "Host(`status.${config.networking.domain}`)";

        service = "gatus";
      };

      services.gatus.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.gatus.settings.web.port}";}];
    };

    postgresql = {
      authRules = ["local gatus gatus peer"];

      ensureDatabases = ["gatus"];

      ensureUsers = [
        {
          name = "gatus";

          ensureDBOwnership = true;
        }
      ];
    };

    gatus = {
      enable = true;

      settings = {
        metrics = true; # /metrics endpoint for prometheus

        storage = let
          retentionDays = 30;

          checkIntervalSeconds = 60; # default gatus interval
        in {
          type = "postgres";

          # `lib/pq` uses `/tmp` by default; force the postgresql service socket dir
          path = "postgresql:///gatus?host=/run/${config.systemd.services.postgresql.serviceConfig.RuntimeDirectory}";

          # per endpoint
          maximum-number-of-results = retentionDays * 24 * 3600 / checkIntervalSeconds;
          maximum-number-of-events = retentionDays * 10;
        };

        ui.default-sort-by = "group"; # name, group, health (https://github.com/TwiN/gatus/blob/fba833f64b7e91b4c06deeefe009f8597e793feb/config/ui/ui.go#L50)

        endpoints = let
          lampacBaseUrl = "https://lampac.${outputs.nixosConfigurations.hel0.config.networking.fqdn}";
        in [
          # keep-sorted start block=yes newline_separated=yes
          {
            name = "alertmanager";
            group = "observability";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:${toString outputs.nixosConfigurations.de0.config.services.prometheus.alertmanager.port}/-/ready"; # `/-/healthy` only proves the process is up

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "bazarr";
            group = "services";

            url = "https://bazarr.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/api/system/ping";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == OK"
            ];
          }

          {
            name = "ftbie";
            group = "services";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:${toString outputs.nixosConfigurations.de0.config.services.prometheus.port}/api/v1/query?query=${lib.escapeURL ''scalar(max(podman_container_health{name="ftbie"}))''}";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == success"
              "[BODY].data.result[1] == 0" # healthy
            ];
          }

          {
            name = "gatus";
            group = "platform";

            url = "https://status.${config.networking.domain}/health";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "goldsrc-proxy-rs-27015";
            group = "services";

            url = "udp://${outputs.nixosConfigurations.hel0.config.networking.fqdn}:27015";
            body = "$GOLDSRC_A2S_INFO_BODY";

            conditions = ["[BODY] == pat(*cstrike*)"]; # `cstrike` is the game directory in the `A2S_INFO` reply
          }

          {
            name = "goldsrc-proxy-rs-28255";
            group = "services";

            url = "udp://${outputs.nixosConfigurations.hel0.config.networking.fqdn}:28255";
            body = "$GOLDSRC_A2S_INFO_BODY";

            conditions = ["[BODY] == pat(*cstrike*)"]; # `cstrike` is the game directory in the `A2S_INFO` reply
          }

          {
            name = "grafana";
            group = "observability";

            url = "${outputs.nixosConfigurations.de0.config.services.grafana.settings.server.root_url}/api/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY].database == ok"
            ];
          }

          {
            name = "headscale";
            group = "platform";

            url = "${outputs.nixosConfigurations.hel0.config.services.headscale.settings.server_url}/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == pass"
            ];
          }

          {
            name = "hermes-agent-alex";
            group = "services";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:${toString outputs.nixosConfigurations.de0.config.services.hermes-agent.instances.alex.settings.platforms.api_server.extra.port}/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == ok"
            ];
          }

          {
            name = "hermes-agent-hilorioze";
            group = "services";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:${toString outputs.nixosConfigurations.de0.config.services.hermes-agent.instances.hilorioze.settings.platforms.api_server.extra.port}/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == ok"
            ];
          }

          {
            name = "hermes-agent-shared";
            group = "services";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:${toString outputs.nixosConfigurations.de0.config.services.hermes-agent.instances.shared.settings.platforms.api_server.extra.port}/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == ok"
            ];
          }

          {
            name = "jellyfin";
            group = "services";

            url = "https://jellyfin.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/health";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "lampac";
            group = "services";

            url = "${lampacBaseUrl}/api/myip"; # simplest health check endpoint

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "lampac-torrserver";
            group = "services";

            url = "${lampacBaseUrl}/ts/echo";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "loki";
            group = "observability";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:3100/ready";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "ncps";
            group = "platform";

            url = "http://${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}:${lib.last (lib.splitString ":" outputs.nixosConfigurations.fakesynology-nixos.config.services.traefik.staticConfigOptions.entryPoints.ncps.address)}/healthz";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "neko";
            group = "services";

            url = "https://neko.${outputs.nixosConfigurations.de0.config.networking.fqdn}/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY] == true"
            ];
          }

          {
            name = "niks3";
            group = "platform";

            url = "https://niks3.${config.networking.domain}/health";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "nix-cache";
            group = "platform";

            url = "https://nix-cache.${config.networking.domain}/nix-cache-info";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "node-exporter-de0";
            group = "telemetry";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:${toString outputs.nixosConfigurations.de0.config.services.prometheus.exporters.node.port}/";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "node-exporter-fakesynology-nixos";
            group = "telemetry";

            url = "http://${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}:${toString outputs.nixosConfigurations.fakesynology-nixos.config.services.prometheus.exporters.node.port}/";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "node-exporter-hel0";
            group = "telemetry";

            url = "http://${outputs.nixosConfigurations.hel0.config.networking.fqdn}:${toString outputs.nixosConfigurations.hel0.config.services.prometheus.exporters.node.port}/";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "pinchflat";
            group = "services";

            url = "https://pinchflat.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/healthcheck";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == ok"
            ];
          }

          {
            name = "podman-exporter-de0";
            group = "telemetry";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:9882/";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "prometheus";
            group = "observability";

            url = "http://${outputs.nixosConfigurations.de0.config.networking.fqdn}:${toString outputs.nixosConfigurations.de0.config.services.prometheus.port}/-/ready"; # `/-/healthy` only proves the process is up

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "prowlarr";
            group = "services";

            url = "https://prowlarr.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/ping";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == OK"
            ];
          }

          {
            name = "qbittorrent";
            group = "services";

            url = "https://qbittorrent.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "radarr";
            group = "services";

            url = "https://radarr.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/ping";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == OK"
            ];
          }

          {
            name = "seerr";
            group = "services";

            # `/status` checks github for updates; `/status/appdata` stays local and verifies config dir access
            url = "https://seerr.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/api/v1/status/appdata";

            conditions = [
              "[STATUS] == 200"

              "[BODY].appDataPermissions == true"
            ];
          }

          {
            name = "sonarr";
            group = "services";

            url = "https://sonarr.${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}/ping";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == OK"
            ];
          }

          {
            name = "tailnet-derp-hel0";
            group = "platform";

            url = "${outputs.nixosConfigurations.hel0.config.services.headscale.settings.server_url}/derp/probe";

            conditions = ["[STATUS] == 200"];
          }
          # keep-sorted end
        ];
      };
    };
  };

  systemd.services.gatus = {
    after = ["prometheus.service"];

    # goldsrc `A2S_INFO` is `b"\xff\xff\xff\xffTSource Engine Query\x00"`
    # a normal YAML/Nix string would send UTF-8 text instead of raw `0xff` bytes
    # gatus expands `$GOLDSRC_A2S_INFO_BODY` before parsing YAML, replacing `body: $GOLDSRC_A2S_INFO_BODY`
    # with `body: !!binary ...`; `yaml.v3` then decodes that scalar to the raw `A2S_INFO` bytes
    environment.GOLDSRC_A2S_INFO_BODY = "!!binary /////1RTb3VyY2UgRW5naW5lIFF1ZXJ5AA=="; # b"\xff\xff\xff\xffTSource Engine Query\x00"
  };
}
