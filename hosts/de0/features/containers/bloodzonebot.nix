{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets = {
      # keep-sorted start
      "credentials/ghcr/hilorioze/pull/token" = {};
      "services/bloodzonebot/amqp-password" = {};
      "services/bloodzonebot/bot-token" = {};
      "services/bloodzonebot/postgres-password" = {};
      "services/bloodzonebot/redis-password" = {};
      "services/bloodzonebot/sentry-dsn" = {};
      "services/postgresql/users/bloodzonebot/hashed-password".owner = config.systemd.services.postgresql-setup.serviceConfig.User;
      "services/rabbitmq/users/bloodzonebot/hashed-password" = {};
      "services/redis/users/bloodzonebot/hashed-password" = {};
      # keep-sorted end
    };

    templates = {
      "config/bloodzonebot.env".content = ''
        BOT_TOKEN=${config.sops.placeholder."services/bloodzonebot/bot-token"}

        SENTRY_DSN=${config.sops.placeholder."services/bloodzonebot/sentry-dsn"}

        POSTGRES_PASSWORD=${config.sops.placeholder."services/bloodzonebot/postgres-password"}
        REDIS_DSN=redis://bloodzonebot:${config.sops.placeholder."services/bloodzonebot/redis-password"}@host.docker.internal:6379/0
        AMQP_DSN=amqp://bloodzonebot:${config.sops.placeholder."services/bloodzonebot/amqp-password"}@host.docker.internal:5672/bloodzonebot
      '';

      "config/redis.acl".content = lib.mkAfter ''
        user bloodzonebot reset on #${config.sops.placeholder."services/redis/users/bloodzonebot/hashed-password"} allkeys allchannels allcommands
      '';
    };
  };

  virtualisation.oci-containers.containers = let
    baseContainer = {
      image = "ghcr.io/hilorioze/bloodzonebot@sha256:58fd141407c6d0e1b7e95bada3b89d861c1f5304784b32d7410b236a72840e1d"; # 056153db20aeeb023dd6b3cc0a01d0f2070bcefd

      login = {
        registry = "ghcr.io";

        username = "hilorioze";
        passwordFile = config.sops.secrets."credentials/ghcr/hilorioze/pull/token".path;
      };

      environment = {
        SENTRY_ENVIRONMENT = "production";

        BLOODZONEAPI_URL = "http://bloodzonebot-bloodzoneapi:8000/";

        POSTGRES_HOST = "host.docker.internal";
        POSTGRES_USER = "bloodzonebot";
      };
      environmentFiles = [config.sops.templates."config/bloodzonebot.env".path];
    };
  in {
    # keep-sorted start block=yes newline_separated=yes
    bloodzonebot-bloodzone-event-publisher =
      baseContainer
      // {
        cmd = ["bloodzone_event_publisher"];
      };

    bloodzonebot-bloodzone-event-telegram-notification-publisher =
      baseContainer
      // {
        cmd = ["bloodzone_event_telegram_notification_publisher"];
      };

    bloodzonebot-bloodzoneapi =
      baseContainer
      // {
        entrypoint = "/venv/bin/uvicorn";
        cmd = [
          "bloodzoneapi.factory:setup_app"
          "--factory"

          "--host"
          "0.0.0.0"
          "--port"
          "8000"
        ];
      };

    bloodzonebot-telegram-bot =
      baseContainer
      // {
        cmd = ["telegram_bot"];
      };

    bloodzonebot-telegram-message-queue-sender =
      baseContainer
      // {
        cmd = ["telegram_message_queue_sender"];
      };
    # keep-sorted end
  };

  services = {
    postgresql = {
      ensureDatabases = ["bloodzonebot"];

      ensureUsers = [
        {
          name = "bloodzonebot";

          ensureDBOwnership = true;
        }
      ];
    };

    rabbitmq.definitions = {
      vhosts = [
        {
          name = "bloodzonebot";
        }
      ];

      users = [
        {
          name = "bloodzonebot";

          password_hash = config.sops.placeholder."services/rabbitmq/users/bloodzonebot/hashed-password";
          hashing_algorithm = "rabbit_password_hashing_sha256";

          tags = [];
        }
      ];

      permissions = [
        {
          user = "bloodzonebot";

          vhost = "bloodzonebot";

          configure = ".*";
          write = ".*";
          read = ".*";
        }
      ];
    };
  };

  systemd.services.postgresql-setup.script = lib.mkAfter ''
    psql --variable=ON_ERROR_STOP=1 <<<${lib.escapeShellArg ''
      SELECT format('ALTER ROLE %I WITH PASSWORD %L', 'bloodzonebot', pg_read_file('${config.sops.secrets."services/postgresql/users/bloodzonebot/hashed-password".path}'))
      \gexec
    ''}
  '';
}
