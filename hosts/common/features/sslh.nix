{lib, ...}: let
  httpsPort = 443;
  httpsInternalPort = 8443;
in {
  networking = {
    # redirect HTTP/3 directly to `traefik` because `sslh` doesn't preserve the client ip when proxying UDP
    firewall = let
      http3UdpDnatAcceptRule = "-p udp --dport ${toString httpsInternalPort} -m conntrack --ctstate DNAT -j ACCEPT";

      http3UdpRedirectRule = "-p udp --dport ${toString httpsPort} -m addrtype --dst-type LOCAL -j REDIRECT --to-ports ${toString httpsInternalPort}";

      natChains = ["PREROUTING" "OUTPUT"];
    in {
      extraCommands = let
        mkAddRule = table: chain: rule: "ip46tables -t ${table} -C ${chain} ${rule} 2>/dev/null || ip46tables -t ${table} -A ${chain} ${rule}";
      in
        lib.concatStringsSep "\n\n" [
          (mkAddRule "filter" "INPUT" http3UdpDnatAcceptRule)

          (lib.concatMapStringsSep "\n" (chain: mkAddRule "nat" chain http3UdpRedirectRule) natChains)
        ];

      extraStopCommands = let
        mkRemoveRule = table: chain: rule: "ip46tables -t ${table} -D ${chain} ${rule} 2>/dev/null || true";
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

      method = "ev"; # `libev` backend scales better than `fork`/`select` for many connections

      settings = {
        transparent = true; # spoof source ip so services see the real remote ip

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

      http3.advertisedPort = httpsPort; # advertise the public port instead of the internal listener port; the firewall rules above redirect traffic to it
    };
  };

  # raise the soft fd limit; `sslh-ev` hits `EMFILE` once the default `1024` file descriptors are exhausted
  systemd.services.sslh.serviceConfig.LimitNOFILE = 4096;
}
