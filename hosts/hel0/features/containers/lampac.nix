{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: let
  peerListenPort = 6881;
in {
  networking.firewall = {
    allowedTCPPorts = [peerListenPort];
    allowedUDPPorts = [peerListenPort];
  };

  sops = {
    secrets = {
      # to generate id:
      #
      # tr --delete --complement 'a-z0-9' </dev/urandom | head --bytes 8

      # keep-sorted start
      "services/lampac/users/danil/id" = {};
      "services/lampac/users/hilorioze/id" = {};
      "services/lampac/users/living-room-tv/id" = {};
      "services/lampac/users/zikkk/id" = {};
      # keep-sorted end
    };

    templates."config/lampac-init.conf" = {
      content = builtins.toJSON {
        LampaWeb.initPlugins.sisi = false;

        accsdb = {
          enable = true;

          users = let
            mkUser = id: {
              inherit id;

              expires = "9999-12-31T23:59:59.9999999";
            };
          in [
            # keep-sorted start
            (mkUser config.sops.placeholder."services/lampac/users/danil/id")
            (mkUser config.sops.placeholder."services/lampac/users/hilorioze/id")
            (mkUser config.sops.placeholder."services/lampac/users/living-room-tv/id")
            (mkUser config.sops.placeholder."services/lampac/users/zikkk/id")
            # keep-sorted end
          ];
        };
      };

      uid = 1000; # match the container's uid
    };
  };

  virtualisation.oci-containers.containers.lampac = {
    image = "ghcr.io/lampac-nextgen/lampac@sha256:fae95162339be4bcce86d52e8cf7eb45998ed80dd7faab8aa974df68bf5f0e42"; # 1.32.1

    labels = {
      "traefik.enable" = "true";

      "traefik.http.routers.lampac.entryPoints" = "http,https";
      "traefik.http.routers.lampac.rule" = "Host(`lampac.${config.networking.fqdn}`)";

      "traefik.http.routers.lampac.service" = "lampac";
      "traefik.http.services.lampac.loadBalancer.server.port" = "9118";
    };

    ports = [
      "${toString peerListenPort}:${toString peerListenPort}/tcp"
      "${toString peerListenPort}:${toString peerListenPort}/udp"
    ];

    volumes = let
      torrServerSettingsFile = pkgs.writeText "torrserver-settings.json" (builtins.toJSON {
        EnableIPv6 = true;

        DisableUpload = true; # not today, thanks

        DisableUPNP = true; # peer ports are already published manually
        PeersListenPort = peerListenPort;
      });
    in [
      "${config.sops.templates."config/lampac-init.conf".path}:/lampac/init.conf:ro"

      # module template; the runtime file ends up in `data/ts/settings.json`
      "${torrServerSettingsFile}:/lampac/module/TorrServer/settings.json:ro"

      "lampac-cache:/lampac/cache"
      "lampac-database:/lampac/database"
    ];
  };
}
