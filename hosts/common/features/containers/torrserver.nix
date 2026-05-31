{
  networking.firewall.allowedTCPPorts = [8090];

  virtualisation.oci-containers.containers.torrserver = {
    image = "ghcr.io/yourok/torrserver@sha256:a06f7edeae97e4c84ee2c3a78c088ffccbb59ea1323ee02d4e158b047896fdbc"; # MatriX.141.4

    # for DHT peer discovery
    extraOptions = ["--network=host"];
  };
}
