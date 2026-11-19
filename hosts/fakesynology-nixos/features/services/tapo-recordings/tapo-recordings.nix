{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  # `surveillance-import.sh` moves the recordings from here into surveillance station
  importPath = "/mnt/surveillance-import";
in {
  sops.secrets = let
    tapoRecordingsSecret = {restartUnits = ["tapo-recordings.service"];};
  in {
    "credentials/tapo/terminal-uuid" = tapoRecordingsSecret;
    "credentials/tapo/token" = tapoRecordingsSecret;

    "credentials/tapo/push/android-id" = tapoRecordingsSecret;
    "credentials/tapo/push/security-token" = tapoRecordingsSecret;
    "credentials/tapo/push/registration-token" = tapoRecordingsSecret;

    "credentials/tapo/cloud-password" = tapoRecordingsSecret;
  };

  services.prometheus.exporters.node.extraFlags = ["--collector.textfile.directory=/run/${config.systemd.services.tapo-recordings.serviceConfig.RuntimeDirectory}"];

  fileSystems.${importPath} = {
    device = "192.168.1.10:/volume1/surveillance-import";

    fsType = "nfs";

    options = [
      # keep-sorted start
      "noauto"
      "x-systemd.automount"
      # keep-sorted end
    ];
  };

  systemd = {
    tmpfiles.rules = ["e /var/lib/private/tapo-recordings/saved/* - - - 3d"]; # the script looks only at yesterday's and today's recordings

    # save camera recordings on their detections from the tapo pushes and the cloud history
    services.tapo-recordings = {
      description = "Tapo camera recordings";

      wantedBy = ["multi-user.target"];

      after = ["network-online.target"];

      wants = ["network-online.target"];

      unitConfig.RequiresMountsFor = importPath;

      serviceConfig = {
        DynamicUser = true;
        ReadWritePaths = importPath; # `DynamicUser` mounts the rest of the system read-only

        StateDirectory = "tapo-recordings";
        RuntimeDirectory = "tapo-recordings";

        LoadCredential = [
          "terminal-uuid:${config.sops.secrets."credentials/tapo/terminal-uuid".path}"
          "token:${config.sops.secrets."credentials/tapo/token".path}"

          "android-id:${config.sops.secrets."credentials/tapo/push/android-id".path}"
          "security-token:${config.sops.secrets."credentials/tapo/push/security-token".path}"
          "registration-token:${config.sops.secrets."credentials/tapo/push/registration-token".path}"

          "cloud-password:${config.sops.secrets."credentials/tapo/cloud-password".path}"
        ];

        ExecStart = "${lib.getExe pkgs.tapo-recordings} ${importPath}";

        Restart = "on-failure"; # a failed cloud request ends the process
        RestartSec = 60;
      };
    };
  };
}
