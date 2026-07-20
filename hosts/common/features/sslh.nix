{
  # keep-sorted start
  config,
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: let
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

      http3.advertisedPort = httpsPort; # keep the advertised HTTP/3 port at `443` so QUIC clients hit the UDP redirect to `8443`
    };
  };

  systemd.services = {
    # raise the soft fd limit; `sslh-ev` hits `EMFILE` once the default `1024` file descriptors are exhausted
    sslh.serviceConfig.LimitNOFILE = 4096;

    # `tailscale`'s `ts-input` chain drops tailnet packets that reenter on `lo`, and `sslh` adds `ip rule add fwmark 0x2 lookup 100` without a `pref`, so the kernel places it after tailscale's catch-all rule, which is `5270`
    tailscaled = let
      tailnetPrefixes = outputs.nixosConfigurations.hel0.config.services.headscale.settings.prefixes;

      tailnetV4Cidr = tailnetPrefixes.v4;
      tailnetV6Cidr = tailnetPrefixes.v6;

      sslhPorts = map (proto: proto.port) config.services.sslh.settings.protocols;

      sslhPortsArg = lib.concatStringsSep "," sslhPorts;
    in {
      path = with pkgs; [
        coreutils
        iproute2
        iptables
      ];

      postStart = lib.mkAfter ''
        wait_for_ts_input() {
          cmd="$1"

          while ! "$cmd" -w -t filter -S ts-input >/dev/null 2>&1; do
            sleep 0.1
          done
        }

        # wait for `tailscale` to finish creating `ts-input` before inserting the rule
        wait_for_ts_input iptables

        while ip rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done
        while ip rule del pref 5260 fwmark 0x2 lookup 100 2>/dev/null; do true; done
        ip rule add pref 5260 fwmark 0x2 lookup 100

        while iptables -w -t filter -D ts-input -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
        iptables -w -t filter -I ts-input 1 -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT

        wait_for_ts_input ip6tables

        while ip -6 rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done
        while ip -6 rule del pref 5260 fwmark 0x2 lookup 100 2>/dev/null; do true; done
        ip -6 rule add pref 5260 fwmark 0x2 lookup 100

        while ip6tables -w -t filter -D ts-input -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
        ip6tables -w -t filter -I ts-input 1 -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT
      '';

      postStop = lib.mkAfter ''
        while ip rule del pref 5260 fwmark 0x2 lookup 100 2>/dev/null; do true; done
        while ip rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done

        while iptables -w -t filter -D ts-input -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done

        while ip -6 rule del pref 5260 fwmark 0x2 lookup 100 2>/dev/null; do true; done
        while ip -6 rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done

        while ip6tables -w -t filter -D ts-input -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
      '';
    };
  };
}
