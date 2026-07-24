{
  # keep-sorted start
  config,
  outputs,
  # keep-sorted end
  ...
}: {
  services.prometheus = {
    enable = true;

    ruleFiles = [./prometheus-rules.yaml];

    scrapeConfigs = [
      # keep-sorted start block=yes newline_separated=yes
      {
        job_name = "gatus";

        static_configs = [
          {
            targets = ["localhost:${toString config.services.gatus.settings.web.port}"];
          }
        ];
      }

      {
        job_name = "node-exporter";

        static_configs = let
          mkNodeTarget = nixosConfiguration: "${nixosConfiguration.config.networking.fqdn}:${toString nixosConfiguration.config.services.prometheus.exporters.node.port}";
        in [
          {
            targets = [
              # keep-sorted start
              (mkNodeTarget outputs.nixosConfigurations.de0)
              (mkNodeTarget outputs.nixosConfigurations.fakesynology-nixos)
              (mkNodeTarget outputs.nixosConfigurations.hel0)
              # keep-sorted end
            ];
          }
        ];
      }

      {
        job_name = "podman-exporter";

        static_configs = [
          {
            targets = ["${outputs.nixosConfigurations.de0.config.networking.fqdn}:9882"];
          }
        ];
      }

      {
        job_name = "synology-snmp";

        metrics_path = "/snmp";

        params = {
          auth = ["public_v2"];
          module = ["synology"];
        };

        static_configs = [
          # keep-sorted start block=yes newline_separated=yes
          {
            targets = ["cex.${config.networking.domain}:9116"];
            labels.instance = "cex";
          }

          {
            targets = ["fakesynology.${config.networking.domain}:9116"];
            labels.instance = "fakesynology";
          }
          # keep-sorted end
        ];

        relabel_configs = [
          {
            target_label = "__param_target";
            replacement = "127.0.0.1";
          }
        ];
      }
      # keep-sorted end
    ];
  };

  systemd.services.prometheus.after = ["prometheus-podman-exporter.service"];
}
