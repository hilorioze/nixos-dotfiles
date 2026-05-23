{
  # keep-sorted start
  config,
  outputs,
  # keep-sorted end
  ...
}: {
  services.fluent-bit = {
    enable = true;

    settings.pipeline = {
      inputs = [
        {
          name = "systemd";

          tag = "systemd.*";

          read_from_tail = true;

          strip_underscores = true; # _SYSTEMD_UNIT -> SYSTEMD_UNIT
        }
      ];

      outputs = [
        {
          name = "loki";

          match = "*";

          host = outputs.nixosConfigurations.de0.config.networking.fqdn;

          labels = "job=fluent-bit,host=${config.networking.hostName}";
          label_keys = "$SYSTEMD_UNIT,$SYSLOG_IDENTIFIER,$PRIORITY";
        }
      ];
    };
  };
}
