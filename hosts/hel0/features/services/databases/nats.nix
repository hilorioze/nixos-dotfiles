{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.templates."services/nats.conf" = {
    content = builtins.toJSON config.services.nats.settings;

    owner = config.services.nats.user;

    restartUnits = ["nats.service"];
  };

  services.nats = {
    enable = true;

    jetstream = true;

    settings.host = "127.0.0.1";
  };

  # the module writes the settings as json, where a `$variable` is a quoted string and not a reference; run nats on the same settings with the secrets rendered in
  systemd.services.nats.serviceConfig.ExecStart = lib.mkForce "${lib.getExe pkgs.nats-server} --config ${config.sops.templates."services/nats.conf".path}";
}
