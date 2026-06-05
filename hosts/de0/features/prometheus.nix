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
      # keep-sorted end
    ];
  };
}
