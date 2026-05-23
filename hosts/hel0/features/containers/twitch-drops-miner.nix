{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  users = [
    # keep-sorted start
    "caligula"
    "hilorioze"
    "zikkk"
    # keep-sorted end
  ];

  userSecretsList =
    map (name: {
      "services/twitch-drops-miner/instances/${name}/users" = {
        inherit (config.users.users.${config.systemd.services.traefik.serviceConfig.User}) group; # bind the secret to the traefik user's group, so changing `services.traefik.group` won't leak it; upstream sets the user's group to "traefik": https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/nixos/modules/services/web-servers/traefik.nix#L160

        mode = "0440"; # give read access for the group we just set above
      };
    })
    users;

  userContainersList =
    map (name: {
      "twitch-drops-miner-${name}" = {
        image = "docker.io/dungfu/twitch-drops-miner@sha256:9c8ff3a35e3cadd162c4c4bcea1c8e83fbdd7094e17f5fedeb5a58c937257269"; # 16.dev.42a490f

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
          "traefik.http.routers.twitch-drops-miner-${name}.middlewares" = "twitch-drops-miner-${name}-auth";
          "traefik.http.middlewares.twitch-drops-miner-${name}-auth.basicAuth.usersFile" = config.sops.secrets."services/twitch-drops-miner/instances/${name}/users".path;
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

                data = 2; # Low availability first
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
  sops.secrets = lib.attrsets.mergeAttrsList userSecretsList;

  virtualisation.oci-containers.containers = lib.attrsets.mergeAttrsList userContainersList;

  systemd.tmpfiles.rules = [
    "d /tmp/twitch-drops-miner-cache 2777 nobody nogroup -" # workaround for `Error: statfs /tmp/twitch-drops-miner-cache: no such file or directory`
  ];
}
