{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  # each also needs its block in de0's `authentik/twitch-drops-miner.yaml`
  users = [
    # keep-sorted start
    "caligula"
    "hilorioze"
    "zikkk"
    # keep-sorted end
  ];

  userContainersList =
    map (name: {
      "twitch-drops-miner-${name}" = {
        image = "docker.io/dungfu/twitch-drops-miner:latest@sha256:72072634a541248d0ac81672c70ce576a4ec4d936e59e8da8cfe4db29b8dbb92";

        # workaround for `PermissionError: [Errno 13] Permission denied: '/TwitchDropsMiner/config/cookies.jar'`
        # see: https://github.com/fireph/docker-twitch-drops-miner#permissions-issues-on-mounted-volumes
        user = "1000:1000";

        labels = {
          "traefik.enable" = "true";

          "traefik.http.routers.twitch-drops-miner-${name}-http.entryPoints" = "http";
          "traefik.http.routers.twitch-drops-miner-${name}-http.rule" = "Host(`twitch-drops-miner-${name}.${config.networking.fqdn}`)";
          "traefik.http.routers.twitch-drops-miner-${name}-http.middlewares" = "redirect-to-https@file";
          "traefik.http.routers.twitch-drops-miner-${name}-http.service" = "noop@internal";

          "traefik.http.routers.twitch-drops-miner-${name}.entryPoints" = "https";
          "traefik.http.routers.twitch-drops-miner-${name}.rule" = "Host(`twitch-drops-miner-${name}.${config.networking.fqdn}`)";
          "traefik.http.routers.twitch-drops-miner-${name}.middlewares" = "oidc-login@file";
          "traefik.http.routers.twitch-drops-miner-${name}.service" = "twitch-drops-miner-${name}";
          "traefik.http.services.twitch-drops-miner-${name}.loadBalancer.server.port" = "5800";
        };

        volumes = let
          twitchDropsMinerSettings = pkgs.writeTextFile {
            name = "twitch-drops-miner-settings.json";

            text = builtins.toJSON {
              dark_mode = true;

              priority_mode = {
                __type = "PriorityMode";

                data = 2; # "Low availability first"
              };
            };
          };
        in [
          "twitch-drops-miner-${name}-config:/TwitchDropsMiner/config"

          "${twitchDropsMinerSettings}:/TwitchDropsMiner/config/settings.json:ro"

          "/tmp/twitch-drops-miner-cache:/TwitchDropsMiner/cache"
        ];
      };
    })
    users;
in {
  virtualisation.oci-containers.containers = lib.attrsets.mergeAttrsList userContainersList;

  systemd.tmpfiles.rules = [
    "d /tmp/twitch-drops-miner-cache 2777 nobody nogroup -" # workaround for `Error: statfs /tmp/twitch-drops-miner-cache: no such file or directory`
  ];
}
