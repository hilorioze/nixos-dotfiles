{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: let
  httpsPort = lib.removePrefix ":" config.services.traefik.staticConfigOptions.entryPoints.https.address;
in {
  networking.firewall = let
    # hand tcp connections to this host's https port to sslh; traefik keeps the port itself, so http/3 and local clients skip sslh
    # tailnet clients reach ssh on its own port, and tailscaled drops tailnet addresses that come back through `lo` from sslh's transparent connections
    redirectRule = "! --in-interface ${config.services.tailscale.interfaceName} --protocol tcp --destination-port ${httpsPort} --match addrtype --dst-type LOCAL --jump REDIRECT --to-ports ${toString config.services.sslh.port}";
  in {
    extraCommands = ''
      ip46tables --table nat --append PREROUTING ${redirectRule}

      ip46tables --append nixos-fw --protocol tcp --destination-port ${toString config.services.sslh.port} --match conntrack --ctstate DNAT --jump nixos-fw-accept
    '';

    # `PREROUTING` lives outside `nixos-fw`, so the firewall doesn't flush the redirect on restart or reload; the first reload after adding it finds nothing to delete
    extraStopCommands = "ip46tables --table nat --delete PREROUTING ${redirectRule} 2>/dev/null || true";
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

  # `sslh-ev` hits `EMFILE` past the default 1024 file descriptors
  systemd.services.sslh.serviceConfig.LimitNOFILE = 4096;
}
