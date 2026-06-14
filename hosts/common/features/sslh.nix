{lib, ...}: let
  httpsPort = 443;
  httpsInternalPort = 8443;
in {
  networking = {
    firewall = let
      http3UdpDnatAcceptRule = "-p udp --dport ${toString httpsInternalPort} -m conntrack --ctstate DNAT -j ACCEPT";

      http3UdpRedirectRule = "-p udp --dport ${toString httpsPort} -m addrtype --dst-type LOCAL -j REDIRECT --to-ports ${toString httpsInternalPort}";

      natChains = ["PREROUTING" "OUTPUT"];
    in {
      extraCommands = let
        mkAddRule = table: chain: rule: "ip46tables -w -t ${table} -C ${chain} ${rule} 2>/dev/null || ip46tables -w -t ${table} -A ${chain} ${rule}";
      in
        lib.concatStringsSep "\n\n" [
          (mkAddRule "filter" "INPUT" http3UdpDnatAcceptRule)

          (lib.concatMapStringsSep "\n" (chain: mkAddRule "nat" chain http3UdpRedirectRule) natChains)
        ];

      extraStopCommands = let
        mkRemoveRule = table: chain: rule: "ip46tables -w -t ${table} -D ${chain} ${rule} 2>/dev/null || true";
      in
        lib.concatStringsSep "\n\n" [
          (lib.concatMapStringsSep "\n" (chain: mkRemoveRule "nat" chain http3UdpRedirectRule) natChains)

          (mkRemoveRule "filter" "INPUT" http3UdpDnatAcceptRule)
        ];
    };
  };

  services = {
    sslh = {
      enable = true;

      settings = {
        transparent = true; # spoof source ip so services see the real remote ip (doesn't work for UDP)

        verbose-connections = 1; # bitmask: stderr=1, syslog=2, logfile=4 (https://github.com/yrutschle/sslh/blob/7eabafc6e2776ed8ea99235b0c05283233425ec6/log.c#L98-L128)

        protocols = [
          # ORDER IS IMPORTANT! `sslh` will try to match the protocols in the order they are defined here, so put more specific ones first (e.g. `ssh`) before more general ones (e.g. `anyprot`)
          {
            name = "ssh";

            host = "localhost";
            port = "22";
          }

          {
            name = "anyprot";

            host = "localhost";
            port = toString httpsInternalPort;
          }
        ];
      };
    };

    traefik.staticConfigOptions.entryPoints.https = {
      address = lib.mkForce ":${toString httpsInternalPort}";

      http3.advertisedPort = httpsPort; # keep the advertised HTTP/3 port at `443` so QUIC clients hit the UDP redirect to `8443`
    };
  };
}
