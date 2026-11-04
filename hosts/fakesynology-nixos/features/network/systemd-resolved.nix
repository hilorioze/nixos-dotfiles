{
  networking.firewall.allowedUDPPorts = [5353]; # required for mdns queries

  services.resolved = {
    enable = true;

    settings.Resolve.MulticastDNS = true;
  };
}
