{
  # agentbox browsers go out through this home address, which anti-bot checks trust more than de0's datacenter one
  services._3proxy = {
    enable = true;

    services = [
      {
        type = "socks";

        bindPort = 1080; # the firewall keeps the port off the internet and the lan; tailscale accepts tailnet traffic, which the headscale acl gates, before it gets there

        auth = ["iponly"]; # with `none` 3proxy skips every acl, including the `denyPrivate` one that keeps the home lan out of the agents' reach

        acl = [{rule = "allow";}];
      }
    ];
  };
}
