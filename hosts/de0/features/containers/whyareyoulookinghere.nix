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
      "services/redis/users/whyareyoulookinghere/hashed-password" = {};
      "services/whyareyoulookinghere/bot-token" = {};
      "services/whyareyoulookinghere/redis-password" = {};
      "services/whyareyoulookinghere/sentry-dsn" = {};
      # keep-sorted end
    };

    templates = {
      "config/whyareyoulookinghere.env".content = ''
        BOT_TOKEN=${config.sops.placeholder."services/whyareyoulookinghere/bot-token"}

        SENTRY_DSN=${config.sops.placeholder."services/whyareyoulookinghere/sentry-dsn"}

        REDIS_DSN=redis://whyareyoulookinghere:${config.sops.placeholder."services/whyareyoulookinghere/redis-password"}@host.docker.internal:6379/1
      '';

      "config/redis.acl".content = lib.mkAfter ''
        user whyareyoulookinghere reset on #${config.sops.placeholder."services/redis/users/whyareyoulookinghere/hashed-password"} allkeys allchannels allcommands
      '';
    };
  };

  virtualisation.oci-containers.containers = let
    baseContainer = {
      image = "ghcr.io/hilorioze/whyareyoulookinghere@sha256:959df7d9aff80becd7ddfd90bb43835bcc46a7ef4899d9ed14d68cd10951944d"; # 9bf3a8c11a1c1b87294848d8ef416dc6491204fd

      login = {
        registry = "ghcr.io";

        username = "hilorioze";
        passwordFile = config.sops.secrets."credentials/ghcr/hilorioze/pull/token".path;
      };

      environmentFiles = ["${config.sops.templates."config/whyareyoulookinghere.env".path}"];
    };
  in {
    # keep-sorted start block=yes newline_separated=yes
    whyareyoulookinghere-school-meals-api =
      baseContainer
      // {
        entrypoint = "/venv/bin/uvicorn";
        cmd = [
          "school_meals_api.__main__:app"

          "--host"
          "0.0.0.0"
        ];
      };

    whyareyoulookinghere-school-meals-bot-publisher =
      baseContainer
      // {
        cmd = ["school_meals_bot_publisher"];

        environment = {
          SCHOOL_MEALS_API = "http://whyareyoulookinghere-school-meals-api:8000/";

          BOT_TARGET_CHAT_ID = "-1001849082241";
          BOT_TARGET_THREAD_ID = "7264";
        };
      };

    whyareyoulookinghere-telegram-bot =
      baseContainer
      // {
        cmd = ["telegram_bot"];

        environment.AUTO_MESSAGE_DELETE = "-1001849082241|7264,-1001849082241|7766";
      };
    # keep-sorted end
  };
}
