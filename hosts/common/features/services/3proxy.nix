{config, ...}: {
  sops = {
    secrets."services/3proxy/users/hilot/hashed-password" = {}; # the hash of `services/hilot/proxy-password` on hel0

    templates."services/3proxy/users" = {
      content = "hilot:CR:${config.sops.placeholder."services/3proxy/users/hilot/hashed-password"}";

      restartUnits = ["3proxy.service"];
    };
  };

  services._3proxy = {
    enable = true;

    usersFile = "/run/credentials/3proxy.service/users";

    namedServices = {
      # keep-sorted start block=yes newline_separated=yes
      # agentboxes go out through this home address, which anti-bot checks trust more than de0's datacenter one
      agentboxes = {
        type = "socks";

        bindPort = 1080; # the firewall keeps the port off the internet and the lan; tailscale accepts tailnet traffic, which the headscale acl gates, before it gets there

        auth = ["iponly"]; # with `none` 3proxy skips every acl, including the `denyPrivate` one that keeps the home lan out of the agents' reach

        acl = [{rule = "allow";}];
      };

      hilot = {
        type = "proxy";

        bindPort = 3128; # the firewall keeps the port off the internet; tailscale accepts tailnet traffic before it gets there

        auth = ["strong"];

        acl = [
          {
            rule = "allow";

            users = ["hilot"];
          }
        ];
      };
      # keep-sorted end
    };
  };

  systemd.services."3proxy".serviceConfig.LoadCredential = ["users:${config.sops.templates."services/3proxy/users".path}"]; # the dynamic user can't read the file where sops puts it
}
