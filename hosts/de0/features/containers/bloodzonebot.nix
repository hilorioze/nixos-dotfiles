{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets = {
      "credentials/ghcr/hilorioze/pull/token" = {};

      # keep-sorted start
      "services/bloodzonebot/amqp-password" = {};
      "services/bloodzonebot/bot-token" = {};
      "services/bloodzonebot/postgres-password" = {};
      "services/bloodzonebot/redis-password" = {};
      "services/bloodzonebot/sentry-dsn" = {};
      # keep-sorted end

      "services/postgresql/users/bloodzonebot/hashed-password" = {
        owner = config.systemd.services.postgresql-setup.serviceConfig.User;

        restartUnits = ["postgresql-setup.service"];
      };

      # keep-sorted start
      "services/rabbitmq/users/bloodzonebot/hashed-password" = {};
      "services/redis/users/bloodzonebot/hashed-password" = {};
      # keep-sorted end
    };

    templates = {
      "services/bloodzonebot.env" = {
        content = ''
          BOT_TOKEN=${config.sops.placeholder."services/bloodzonebot/bot-token"}

          SENTRY_DSN=${config.sops.placeholder."services/bloodzonebot/sentry-dsn"}

          POSTGRES_PASSWORD=${config.sops.placeholder."services/bloodzonebot/postgres-password"}
          REDIS_DSN=redis://bloodzonebot:${config.sops.placeholder."services/bloodzonebot/redis-password"}@host.docker.internal:6379/0
          AMQP_DSN=amqp://bloodzonebot:${config.sops.placeholder."services/bloodzonebot/amqp-password"}@host.docker.internal:5672/bloodzonebot
        '';

        restartUnits = [
          # keep-sorted start
          "podman-bloodzonebot-bloodzone-event-publisher.service"
          "podman-bloodzonebot-bloodzone-event-telegram-notification-publisher.service"
          "podman-bloodzonebot-bloodzoneapi.service"
          "podman-bloodzonebot-telegram-bot.service"
          "podman-bloodzonebot-telegram-message-queue-sender.service"
          # keep-sorted end
        ];
      };

      "services/redis.acl".content = lib.mkAfter ''
        user bloodzonebot reset on #${config.sops.placeholder."services/redis/users/bloodzonebot/hashed-password"} allkeys allchannels allcommands
      '';
    };
  };

  virtualisation.oci-containers.containers = let
    baseContainer = {
      image = "ghcr.io/hilorioze/bloodzonebot@sha256:2b35e093578c15e1e22a026d1aea0a023b20edbb94063507a7d63deef4bbd2a9"; # c5929b1

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
      environmentFiles = [config.sops.templates."services/bloodzonebot.env".path];
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
