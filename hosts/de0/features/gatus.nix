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
            name = "attic";
            group = "platform";

            url = outputs.nixosConfigurations.de0.config.services.atticd.settings.api-endpoint;

            conditions = ["[STATUS] == 200"];
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
            name = "garage";
            group = "platform";

            url = "https://garage-admin.${outputs.nixosConfigurations.de0.config.networking.fqdn}/health";

            conditions = ["[STATUS] == 200"];
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
