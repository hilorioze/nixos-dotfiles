{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  stateDirectory = "telegram-bot-api";

  directory = "/var/lib/${stateDirectory}";

  apiPort = 8081; # telegram-bot-api's default port
  filesPort = 8082;

  # any bot can use the server after `logOut` from telegram's, and a `--local` one sends files of its own disk by their path, so traefik lets only these bots through
  botIds = [8658908506];

  # the official telegram desktop; telegram refuses bots the published key of the android app, which hilot logs in with
  telegram = {
    api_id = 2040;
    api_hash = "b18441a1ff607e10a989891a5462e627";
  };

  # the files of a `--local` server under the paths of telegram's server: `getFile` gives the file's absolute path, which a remote client puts after `/file/bot<token>/`
  filesConfig = (pkgs.formats.toml {}).generate "telegram-bot-api-files.toml" {
    general = {
      host = "127.0.0.1";
      port = filesPort;

      root = directory;
    };

    # each segment matches apart, so a path can't leave the storage, and the token of the request picks the directory, so a bot reads only its own files;
    # traefik merges the double slash between the token and the absolute path
    advanced.rewrites = [
      {
        source = "/file/bot{*}${directory}/{*}/{*}/{*}";
        destination = "/$1/$3/$4";
      }
    ];
  };
in {
  # the bot of hilorioze's hermes on de0, which takes files of up to 2 GB from it, and through which hilot sends rich messages of up to 2 GB;
  # a bot moves here after `curl https://api.telegram.org/bot<token>/logOut`, and back to telegram's server after `logOut` here
  users = {
    users.telegram-bot-api = {
      isSystemUser = true;

      group = config.users.groups.telegram-bot-api.name;
    };

    groups.telegram-bot-api = {};
  };

  # under telegram's own paths, so a client takes the server as is; see `tofu/cloudflare/services.tofu`
  services.traefik = {
    # an upload of up to 2 GB takes longer than the minute traefik gives a whole request
    staticConfigOptions.entryPoints.https.transport.respondingTimeouts.readTimeout = "15m";

    dynamicConfigOptions.http = let
      host = "telegram-bot-api.${config.networking.domain}";

      # python-telegram-bot percent-encodes the colon of the token in the url of a file
      botPaths = prefix: "PathRegexp(`^${prefix}/bot(${lib.concatMapStringsSep "|" toString botIds})(:|%3A)`)";
    in {
      routers = {
        # the root answers with a json error, for gatus
        telegram-bot-api = {
          entryPoints = ["https"];
          rule = "Host(`${host}`) && (Path(`/`) || ${botPaths ""})";

          observability.accessLogs = false; # the paths carry the token

          service = "telegram-bot-api";
        };

        telegram-bot-api-files = {
          entryPoints = ["https"];
          rule = "Host(`${host}`) && ${botPaths "/file"}";

          observability.accessLogs = false; # the paths carry the token

          service = "telegram-bot-api-files";
        };
      };

      services = {
        telegram-bot-api.loadBalancer.servers = [{url = "http://127.0.0.1:${toString apiPort}";}];

        telegram-bot-api-files.loadBalancer.servers = [{url = "http://127.0.0.1:${toString filesPort}";}];
      };
    };
  };

  systemd = {
    services = let
      # tdlib keeps the files readable only to their owner, so the files are served by the same user
      shared.serviceConfig = {
        User = config.users.users.telegram-bot-api.name;
        Group = config.users.users.telegram-bot-api.group;

        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;

        Restart = "on-failure";
        RestartSec = 10;
      };
    in {
      telegram-bot-api = lib.mkMerge [
        shared

        {
          description = "Telegram Bot API server";

          wantedBy = ["multi-user.target"];

          after = ["network-online.target"];
          wants = ["network-online.target"];

          serviceConfig = {
            StateDirectory = stateDirectory;

            ExecStart = lib.escapeShellArgs [
              (lib.getExe pkgs.telegram-bot-api)
              "--local"
              "--api-id=${toString telegram.api_id}"
              "--api-hash=${telegram.api_hash}"
              "--http-ip-address=127.0.0.1"
              "--http-port=${toString apiPort}"
              "--dir=${directory}"
              "--temp-dir=/tmp"
            ];
          };
        }
      ];

      # a `--local` server doesn't serve its files, de0's hermes takes them from here
      telegram-bot-api-files = lib.mkMerge [
        shared

        {
          description = "Files of the Telegram Bot API server";

          wantedBy = ["multi-user.target"];

          after = ["telegram-bot-api.service"];

          serviceConfig = {
            ReadOnlyPaths = [directory];

            ExecStart = "${lib.getExe pkgs.static-web-server} --config-file=${filesConfig}";
          };
        }
      ];
    };

    # the server keeps every file it downloads; the files hermes hasn't taken within a day go, the server downloads them again when asked
    tmpfiles.settings.telegram-bot-api = lib.genAttrs (map (files: "${directory}/*/${files}") [
      # keep-sorted start
      "animations"
      "documents"
      "music"
      "photos"
      "stickers"
      "temp"
      "thumbnails"
      "video_notes"
      "videos"
      "voice"
      # keep-sorted end
    ]) (_: {e.age = "1d";});
  };
}
