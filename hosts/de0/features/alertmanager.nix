{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  sops.secrets."services/alertmanager/telegram-bot-token".owner = config.systemd.services.alertmanager.serviceConfig.User;

  users = {
    users.alertmanager = {
      isSystemUser = true;

      group = config.users.groups.alertmanager.name;
    };

    groups.alertmanager = {};
  };

  services.prometheus = {
    alertmanagers = [
      {
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.alertmanager.port}"];
          }
        ];
      }
    ];

    alertmanager = {
      enable = true;

      configuration = {
        route = {
          receiver = "telegram";

          group_by = ["alertname" "instance"];
        };

        receivers = [
          {
            name = "telegram";

            telegram_configs = [
              {
                bot_token_file = config.sops.secrets."services/alertmanager/telegram-bot-token".path;

                chat_id = 5421773461;

                send_resolved = true;
              }
            ];
          }
        ];
      };
    };
  };

  systemd.services.alertmanager.serviceConfig = {
    DynamicUser = lib.mkForce false;

    User = config.users.users.alertmanager.name;
  };
}
