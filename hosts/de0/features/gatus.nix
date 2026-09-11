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
          # keep-sorted start
          de0Config = outputs.nixosConfigurations.de0.config;
          fakesynologyNixosConfig = outputs.nixosConfigurations.fakesynology-nixos.config;
          hel0Config = outputs.nixosConfigurations.hel0.config;
          # keep-sorted end

          # keep-sorted start
          de0Host = de0Config.networking.fqdn;
          hel0Host = hel0Config.networking.fqdn;
          # keep-sorted end

          prometheusBaseUrl = "http://${de0Host}:${toString de0Config.services.prometheus.port}";

          headscaleBaseUrl = hel0Config.services.headscale.settings.server_url;

          lampacBaseUrl = "https://lampac.${hel0Host}";

          mailserverHost = hel0Config.mailserver.fqdn;

          mkGoldsrcProxyEndpoint = port: {
            name = "goldsrc-proxy-rs-${toString port}";
            group = "services";

            url = "udp://${hel0Host}:${toString port}";
            body = "$GOLDSRC_A2S_INFO_BODY";

            conditions = ["[BODY] == pat(*cstrike*)"]; # `cstrike` is the game directory in the `A2S_INFO` reply
          };

          mkNodeExporterEndpoint = nixosConfig: {
            name = "node-exporter-${nixosConfig.networking.hostName}";
            group = "telemetry";

            url = "http://${nixosConfig.networking.fqdn}:${toString nixosConfig.services.prometheus.exporters.node.port}/";

            conditions = ["[STATUS] == 200"];
          };

          mkSnmpExporterEndpoint = hostName: {
            name = "snmp-exporter-${hostName}";
            group = "telemetry";

            url = "http://${hostName}.${config.networking.domain}:9116/snmp?target=127.0.0.1&module=synology&auth=public_v2";

            conditions = [
              "[STATUS] == 200"

              "[BODY] == pat(*snmp_scrape_duration_seconds*)"
            ];
          };
        in [
          # keep-sorted start block=yes newline_separated=yes case=no by_regex=(?:name\s*=\s*"|\(mk)([^"\s]+)
          {
            name = "alertmanager";
            group = "observability";

            url = "http://${de0Host}:${toString de0Config.services.prometheus.alertmanager.port}/-/ready"; # `/-/healthy` only proves the process is up

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "authentik";
            group = "platform";

            url = "https://idm.${config.networking.domain}/-/health/ready/";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "authentik-ldap";
            group = "platform";

            url = "tls://${de0Host}:6636";

            conditions = ["[CONNECTED] == true"];
          }

          {
            name = "deadlocked-relay-egress";
            group = "services";

            url = "https://deadlocked-relay.${fakesynologyNixosConfig.networking.fqdn}/client";

            headers = {
              Connection = "Upgrade";
              Upgrade = "websocket";

              Sec-WebSocket-Key = "AAAAAAAAAAAAAAAAAAAAAA=="; # RFC 6455 format: 16-byte nonce encoded as RFC 4648 base64
              Sec-WebSocket-Version = "13";
            };

            conditions = ["[STATUS] == 101"];
          }

          {
            name = "deadlocked-relay-ingest";
            group = "services";

            url = "tcp://${fakesynologyNixosConfig.networking.fqdn}:6346";
            body = "$DEADLOCKED_RELAY_HEALTH_BODY";

            conditions = [
              "[CONNECTED] == true"

              "[BODY] == 0000000000000000"
            ];
          }

          {
            name = "ftbie";
            group = "services";

            url = "${prometheusBaseUrl}/api/v1/query?query=${lib.escapeURL ''scalar(max(podman_container_health{name="ftbie"}))''}";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == success"
              "[BODY].data.result[1] == any(0, 2)" # `healthy` or `starting`
            ];
          }

          {
            name = "gatus";
            group = "platform";

            url = "https://status.${config.networking.domain}/health";

            conditions = ["[STATUS] == 200"];
          }

          (mkGoldsrcProxyEndpoint 27015)

          (mkGoldsrcProxyEndpoint 28255)

          {
            name = "grafana";
            group = "observability";

            url = "${de0Config.services.grafana.settings.server.root_url}/api/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY].database == ok"
            ];
          }

          {
            name = "headscale";
            group = "platform";

            url = "${headscaleBaseUrl}/health";

            conditions = [
              "[STATUS] == 200"

              "[BODY].status == pass"
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

            url = "http://${de0Host}:3100/ready";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "mailserver-imaps";
            group = "platform";

            url = "tls://${mailserverHost}:${toString hel0Config.services.dovecot2.settings."service imap-login"."inet_listener imaps".port}";
            body = "A001 CAPABILITY\r\n";

            conditions = [
              "[CONNECTED] == true"

              "[BODY] == pat(* OK *IMAP4rev1*)"
            ];
          }

          {
            name = "mailserver-managesieve";
            group = "platform";

            url = "tcp://${mailserverHost}:4190";
            body = "NOOP\r\n";

            conditions = [
              "[CONNECTED] == true"

              "[BODY] == pat(*\"IMPLEMENTATION\" *\"SIEVE\" *\"VERSION\" \"1.0\"*OK*)"
            ];
          }

          {
            name = "mailserver-submissions";
            group = "platform";

            url = "tls://${mailserverHost}:465";
            body = "QUIT\r\n";

            conditions = [
              "[CONNECTED] == true"

              "[BODY] == pat(220 ${mailserverHost} ESMTP*)"
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

          (mkNodeExporterEndpoint de0Config)

          (mkNodeExporterEndpoint fakesynologyNixosConfig)

          (mkNodeExporterEndpoint hel0Config)

          {
            name = "podman-exporter-de0";
            group = "telemetry";

            url = "http://${de0Host}:9882/";

            conditions = ["[STATUS] == 200"];
          }

          {
            name = "prometheus";
            group = "observability";

            url = "${prometheusBaseUrl}/-/ready"; # `/-/healthy` only proves the process is up

            conditions = ["[STATUS] == 200"];
          }

          (mkSnmpExporterEndpoint "cex")

          (mkSnmpExporterEndpoint "fakesynology")

          {
            name = "tailnet-derp-hel0";
            group = "platform";

            url = "${headscaleBaseUrl}/derp/probe";

            conditions = ["[STATUS] == 200"];
          }
          # keep-sorted end
        ];
      };
    };
  };

  systemd.services.gatus = {
    after = [
      # keep-sorted start
      "postgresql.service"
      "prometheus.service"
      # keep-sorted end
    ];

    requires = ["postgresql.service"];

    # both probes send raw binary protocol payloads
    # normal YAML strings cannot represent arbitrary bytes such as `0xff` or NUL directly
    # gatus expands these environment variables before parsing YAML; `yaml.v3` decodes `!!binary` to raw bytes
    environment = {
      # keep-sorted start
      DEADLOCKED_RELAY_HEALTH_BODY = "!!binary AAAAAjAwMDAwMDAwMDAwMDAwMDA="; # b"\x00\x00\x00\x020000000000000000"
      GOLDSRC_A2S_INFO_BODY = "!!binary /////1RTb3VyY2UgRW5naW5lIFF1ZXJ5AA=="; # b"\xff\xff\xff\xffTSource Engine Query\x00"
      # keep-sorted end
    };
  };
}
