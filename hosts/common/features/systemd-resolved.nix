{
  networking.firewall.allowedUDPPorts = [5353]; # required for mDNS queries

  services.resolved = {
    enable = true;

    settings.Resolve.MulticastDNS = true;
  };
}
