let
  peerListenPort = 32000;
in {
  imports = [../../../common/features/containers/torrserver.nix];

  networking.firewall = {
    allowedTCPPorts = [peerListenPort];
    allowedUDPPorts = [peerListenPort];
  };

  virtualisation.oci-containers.containers.torrserver = let
    settingsFile = builtins.toFile "torrserver-settings.json" (builtins.toJSON {
      BitTorr = {
        # keep-sorted start
        CacheSize = 134217728; # 128 MiB
        ConnectionsLimit = 25;
        DisableUpload = true;
        EnableIPv6 = true;
        EnableRutorSearch = true;
        PeersListenPort = peerListenPort;
        PreloadCache = 50;
        ReaderReadAHead = 95;
        ResponsiveMode = true;
        RetrackersMode = 1;
        ShowFSActiveTorr = true;
        TorrentDisconnectTimeout = 30;
        # keep-sorted end
      };
    });
  in {
    volumes = ["${settingsFile}:/opt/ts/config/settings.json:ro"];
  };
}
