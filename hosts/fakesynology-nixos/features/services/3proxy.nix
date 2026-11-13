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

    services = [
      {
        type = "proxy";

        bindPort = 3128; # the firewall keeps the port off the internet; tailscale accepts tailnet traffic before it gets there

        auth = ["strong"];

        acl = [
          {
            rule = "allow";

            users = ["hilot"];
          }
        ];
      }
    ];
  };

  systemd.services."3proxy".serviceConfig.LoadCredential = ["users:${config.sops.templates."services/3proxy/users".path}"]; # the dynamic user can't read the file where sops puts it
}
