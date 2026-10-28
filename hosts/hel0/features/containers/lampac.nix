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
      "services/lampac/users/guest/id" = {};
      "services/lampac/users/hilorioze/id" = {};
      "services/lampac/users/living-room-tv/id" = {};
      "services/lampac/users/zikkk/id" = {};
      # keep-sorted end
    };

    templates."services/lampac/init.conf" = {
      content = builtins.toJSON {
        LampaWeb.initPlugins.sisi = false;

        accsdb = {
          enable = true;

          users = let
            mkUser = name: {
              id = config.sops.placeholder."services/lampac/users/${name}/id";

              expires = "9999-12-31T23:59:59.9999999";
            };
          in [
            # keep-sorted start
            (mkUser "danil")
            (mkUser "guest")
            (mkUser "hilorioze")
            (mkUser "living-room-tv")
            (mkUser "zikkk")
            # keep-sorted end
          ];
        };
      };

      uid = 1000; # match the container's uid

      restartUnits = ["podman-lampac.service"];
    };
  };

  virtualisation.oci-containers.containers.lampac = {
    image = "ghcr.io/lampac-nextgen/lampac:1.87.2@sha256:54450e9eeada130754471ed857022ae83354433bbcac125d2fb0a532b211938e";

    labels = {
      "traefik.enable" = "true";

      "traefik.http.routers.lampac.entryPoints" = "http,https";
      "traefik.http.routers.lampac.rule" = "Host(`lampac.${config.networking.fqdn}`)";

      "traefik.http.routers.lampac.service" = "lampac";
      "traefik.http.services.lampac.loadBalancer.server.port" = "9118";
    };

    ports = [
      # keep-sorted start
      "${toString peerListenPort}:${toString peerListenPort}/tcp"
      "${toString peerListenPort}:${toString peerListenPort}/udp"
      # keep-sorted end
    ];

    volumes = let
      torrServerSettingsFile = pkgs.writeText "torrserver-settings.json" (builtins.toJSON {
        EnableIPv6 = true;

        DisableUpload = true; # not today, thanks

        DisableUPNP = true; # peer ports are already published manually
        PeersListenPort = peerListenPort;
      });
    in [
      "${config.sops.templates."services/lampac/init.conf".path}:/lampac/init.conf:ro"

      # module template; the runtime file ends up in `data/ts/settings.json`
      "${torrServerSettingsFile}:/lampac/module/TorrServer/settings.json:ro"

      # keep-sorted start
      "lampac-cache:/lampac/cache"
      "lampac-database:/lampac/database"
      # keep-sorted end
    ];
  };
}
