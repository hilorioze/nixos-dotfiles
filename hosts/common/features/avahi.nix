{config, ...}: {
  services.avahi = {
    enable = true;

    nssmdns4 = config.services.avahi.ipv4;
    # leave `nssmdns6` disabled: `glibc` probes IPv6 first, and `mdns` returns `NOTFOUND` for IPv4-only `.local` names before the IPv4 fallback runs
    # nssmdns6 = config.services.avahi.ipv6;

    publish = {
      enable = true;

      addresses = true;
      workstation = true;
      domain = true;
    };
  };
}
