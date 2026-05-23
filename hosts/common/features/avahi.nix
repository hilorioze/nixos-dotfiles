{config, ...}: {
  services.avahi = {
    enable = true;

    nssmdns4 = config.services.avahi.ipv4;
    nssmdns6 = config.services.avahi.ipv6;

    publish = {
      enable = true;

      addresses = true;
      workstation = true;
      domain = true;
    };
  };
}
