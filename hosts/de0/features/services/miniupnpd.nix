{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: let
  httpPort = 5000; # fixed, so the firewall can open it to agentboxes

  stateDirectory = "miniupnpd";
in {
  networking.firewall.interfaces.agentbox = {
    allowedTCPPorts = [httpPort];
    allowedUDPPorts = [1900]; # ssdp, how agentboxes discover the gateway
  };

  # agentboxes publish their non-http services through it from one shared pool
  services.miniupnpd = {
    enable = true;

    internalIPs = ["agentbox"];

    externalInterface = config.networking.nat.externalInterface;

    appendConfig = ''
      http_port=${toString httpPort}

      # oci translates the public ipv4 to the interface's private one
      ext_ip=${(lib.importJSON ../../../servers.json).${config.networking.hostName}.ipv4}

      lease_file=/var/lib/${stateDirectory}/leases

      # mappings take the pool only, above the host's ephemeral ports and where none of its services listen; secure mode keeps each to its requester's own address
      allow 61000-65535 ${config.virtualisation.agentbox.bridge.address}/${toString config.virtualisation.agentbox.bridge.prefixLength} 1-65535
      deny 0-65535 0.0.0.0/0 0-65535
    '';
  };

  systemd.services.miniupnpd = {
    # miniupnpd adds its rules to the module's table; a switch to nftables would otherwise start it before the table loads
    after = ["nftables.service"];
    requires = ["nftables.service"];

    serviceConfig.StateDirectory = stateDirectory;
  };
}
