{config, ...}: {
  services.avahi = {
    enable = true;

    nssmdns4 = config.services.avahi.ipv4;
    # leave `nssmdns6` disabled: glibc probes ipv6 first, and mdns returns NOTFOUND for ipv4-only `.local` names before the ipv4 fallback runs
    # nssmdns6 = config.services.avahi.ipv6;

    publish = {
      enable = true;

      addresses = true;
      workstation = true;
      domain = true;
    };
  };

  # resolved answers mdns by default too: its address ptr records point at the plain hostname, avahi sees them as a conflict and renames the host every ~20s, flooding the lan with probes
  services.resolved.settings.Resolve.MulticastDNS = "resolve";
}
