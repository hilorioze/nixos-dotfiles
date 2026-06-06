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
      # keep-sorted start
      "services/lampac/root-passwd".uid = 1000; # match the container's uid
      "services/lampac/shared-passwd" = {};
      # keep-sorted end
    };

    templates."config/lampac-init.conf" = {
      content = builtins.toJSON {
        accsdb = {
          enable = true;

          shared_passwd = config.sops.placeholder."services/lampac/shared-passwd";
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
      "${config.sops.secrets."services/lampac/root-passwd".path}:/lampac/passwd:ro"
      "${config.sops.templates."config/lampac-init.conf".path}:/lampac/init.conf:ro"

      # module template; the runtime file ends up in `data/ts/settings.json`
      "${torrServerSettingsFile}:/lampac/module/TorrServer/settings.json:ro"

      "lampac-cache:/lampac/cache"
      "lampac-database:/lampac/database"
    ];
  };
}
