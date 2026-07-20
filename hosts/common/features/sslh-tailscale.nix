{
  # keep-sorted start
  config,
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: let
  tailnetPrefixes = outputs.nixosConfigurations.hel0.config.services.headscale.settings.prefixes;

  tailnetV4Cidr = tailnetPrefixes.v4;
  tailnetV6Cidr = tailnetPrefixes.v6;

  sslhPortsArg = lib.concatStringsSep "," (map (proto: proto.port) config.services.sslh.settings.protocols);
in {
  systemd.services = {
    sslh.preStart = lib.mkAfter ''
      # place `sslh`'s routing rules before `tailscale`'s catch-all rule at `5270`
      while ip rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done
      ip rule add pref 5260 fwmark 0x2 lookup 100

      while ip -6 rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done
      ip -6 rule add pref 5260 fwmark 0x2 lookup 100
    '';

    tailscaled = {
      path = with pkgs; [
        # keep-sorted start
        coreutils
        iptables
        # keep-sorted end
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

        # allow tailnet connections proxied by `sslh` to reenter through `lo` before `tailscale` drops CGNAT traffic
        while iptables -w -t filter -D ts-input -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
        iptables -w -t filter -I ts-input 1 -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT

        wait_for_ts_input ip6tables

        # mirror the IPv4 exception in case `tailscale` implements the equivalent source validation, but for IPv6 (it currently doesn't, but marked as `TODO:`)
        while ip6tables -w -t filter -D ts-input -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
        ip6tables -w -t filter -I ts-input 1 -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT
      '';

      postStop = lib.mkAfter ''
        while iptables -w -t filter -D ts-input -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done

        while ip6tables -w -t filter -D ts-input -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
      '';
    };
  };
}
