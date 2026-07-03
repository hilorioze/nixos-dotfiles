{config, ...}: {
  users.users.${config.services.qbittorrent.user}.extraGroups = [config.users.groups.media.name];

  services = {
    qbittorrent = {
      enable = true;

      serverConfig = {
        LegalNotice.Accepted = true;

        BitTorrent.Session = {
          GlobalUPSpeedLimit = 1; # KiB/s
          IgnoreLimitsOnLAN = true;
          IncludeOverheadInLimits = true; # count protocol overhead (headers/control traffic) against the limit

          TorrentStopCondition = "FilesChecked";

          SeedingOutgoingConnectionsEnabled = false; # only applies after the torrent enters seeding state

          DisableAutoTMMByDefault = false; # enable automatic torrent management so category save paths take effect
        };

        Preferences.Downloads = let
          mediaRoot = "/srv/media";
        in {
          SavePath = "${mediaRoot}/downloads/manual/";

          TempPathEnabled = true;
          TempPath = "${mediaRoot}/downloads/incomplete/";
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.qbittorrent = {
        entryPoints = ["https"];
        rule = "Host(`qbittorrent.${config.networking.fqdn}`)";

        service = "qbittorrent";
      };

      services.qbittorrent.loadBalancer.servers = [{url = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";}];
    };
  };

  systemd.services.qbittorrent.serviceConfig.UMask = "0002";
}
