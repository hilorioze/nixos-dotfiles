{
  networking.resolvconf.useLocalResolver = false; # don't point `resolv.conf` to `localhost`; tailscale will route split dns queries back here anyway

  services.pdns-recursor = {
    enable = true;

    settings.incoming.non_local_bind = true; # bind to configured IPs before their interfaces are up
  };
}
