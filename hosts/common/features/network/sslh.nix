{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: let
  httpsPort = lib.removePrefix ":" config.services.traefik.staticConfigOptions.entryPoints.https.address;
in {
  networking = {
    firewall.extraInputRules = "tcp dport ${toString config.services.sslh.port} ct status dnat accept";

    nftables.tables.sslh = {
      family = "inet";

      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;

          # hand tcp connections to this host's https port to sslh; traefik keeps the port itself, so http/3 and local clients skip sslh
          # tailnet clients reach ssh on its own port, and tailscaled drops tailnet addresses that come back through `lo` from sslh's transparent connections
          iifname != "${config.services.tailscale.interfaceName}" tcp dport ${httpsPort} fib daddr type local redirect to :${toString config.services.sslh.port}
        }
      '';
    };
  };

  services.sslh = {
    enable = true;

    port = 8443;

    method = "ev"; # `libev` handles many connections in one process

    settings = {
      transparent = true; # let sshd and traefik see client addresses

      protocols = [
        {
          name = "ssh";

          host = "localhost";
          port = toString (lib.head config.services.openssh.ports);
        }

        {
          name = "tls";

          host = "localhost";
          port = httpsPort;
        }
      ];
    };
  };

  # a static user, since a dynamic one no longer resolves in the module's `postStop`; its `iptables --uid-owner sslh` fails there and leaves the `ip rule` behind
  users = {
    users.sslh = {
      isSystemUser = true;

      group = "sslh";
    };

    groups.sslh = {};
  };

  systemd.services.sslh = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;

      LimitNOFILE = 4096; # `sslh-ev` hits `EMFILE` past the default 1024 file descriptors
    };

    # clear the routing an earlier failed stop left, as the module already does for its iptables rules; its `ip rule add` fails on a leftover
    preStart = lib.mkBefore ''
      while ip rule del fwmark 0x2 lookup 100 2>/dev/null; do :; done
      while ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null; do :; done

      while ip -6 rule del fwmark 0x2 lookup 100 2>/dev/null; do :; done
      while ip -6 route del local ::/0 dev lo table 100 2>/dev/null; do :; done
    '';
  };
}
