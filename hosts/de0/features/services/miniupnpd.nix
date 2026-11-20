{config, ...}: let
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

      # oci translates the public ipv4 to the interface's private one; the firewall filters what stun's nat test probes, which doesn't affect the mappings
      ext_perform_stun=allow-filtered
      ext_stun_host=stun.cloudflare.com

      lease_file=/var/lib/${stateDirectory}/leases

      # mappings take the pool only, above the host's ephemeral ports and where none of its services listen; secure mode keeps each to its requester's own address
      allow 61000-65535 ${config.virtualisation.agentbox.bridge.address}/${toString config.virtualisation.agentbox.bridge.prefixLength} 1-65535
      deny 0-65535 0.0.0.0/0 0-65535
    '';
  };

  systemd.services.miniupnpd.serviceConfig = {
    StateDirectory = stateDirectory;

    # miniupnpd exits when stun fails on start
    Restart = "on-failure";
    RestartSec = "1min";
  };
}
