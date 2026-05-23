{
  networking.firewall.allowedTCPPorts = [8090];

  virtualisation.oci-containers.containers.torrserver = {
    image = "ghcr.io/yourok/torrserver@sha256:afed5d6ff406e6a32bad627a225d8c36d344d48f23df9c29c9b6d5324cd491e6"; # MatriX.141

    # for DHT peer discovery
    extraOptions = ["--network=host"];
  };
}
