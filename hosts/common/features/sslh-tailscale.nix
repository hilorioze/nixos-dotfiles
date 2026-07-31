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
  # keep custom rules outside `tailscale`'s managed chains so `netfilter` state changes preserve them
  services.tailscale = {
    extraUpFlags = ["--netfilter-mode=nodivert"];

    extraSetFlags = ["--netfilter-mode=nodivert"];
  };

  systemd.services = {
    sslh.preStart = lib.mkAfter ''
      # place `sslh`'s routing rules before `tailscale`'s catch-all rule at `5270`
      while ip rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done
      ip rule add pref 5260 fwmark 0x2 lookup 100

      while ip -6 rule del fwmark 0x2 lookup 100 2>/dev/null; do true; done
      ip -6 rule add pref 5260 fwmark 0x2 lookup 100
    '';

    sslh-tailscale = {
      after = ["tailscaled-set.service"];

      partOf = ["tailscaled.service"];

      requires = ["tailscaled-set.service"];

      wantedBy = [
        # keep-sorted start
        "multi-user.target"
        "tailscaled.service"
        # keep-sorted end
      ];

      path = [pkgs.iptables];

      serviceConfig = {
        RemainAfterExit = true;

        Type = "oneshot";
      };

      script = ''
        iptables -w -t filter -I INPUT 1 -j ts-input

        # allow tailnet connections proxied by `sslh` to reenter through `lo` before `tailscale` drops CGNAT traffic
        iptables -w -t filter -I INPUT 1 -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT

        iptables -w -t filter -I FORWARD 1 -j ts-forward
        iptables -w -t nat -I POSTROUTING 1 -j ts-postrouting

        ip6tables -w -t filter -I INPUT 1 -j ts-input

        # mirror the IPv4 exception in case `tailscale` implements the equivalent source validation, but for IPv6 (it currently doesn't, but marked as `TODO:`)
        ip6tables -w -t filter -I INPUT 1 -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT

        ip6tables -w -t filter -I FORWARD 1 -j ts-forward
        ip6tables -w -t nat -I POSTROUTING 1 -j ts-postrouting
      '';

      preStop = ''
        while iptables -w -t filter -D INPUT -i lo -s ${tailnetV4Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
        while iptables -w -t filter -D INPUT -j ts-input 2>/dev/null; do true; done
        while iptables -w -t filter -D FORWARD -j ts-forward 2>/dev/null; do true; done
        while iptables -w -t nat -D POSTROUTING -j ts-postrouting 2>/dev/null; do true; done

        while ip6tables -w -t filter -D INPUT -i lo -s ${tailnetV6Cidr} -p tcp -m multiport --dports ${sslhPortsArg} -j ACCEPT 2>/dev/null; do true; done
        while ip6tables -w -t filter -D INPUT -j ts-input 2>/dev/null; do true; done
        while ip6tables -w -t filter -D FORWARD -j ts-forward 2>/dev/null; do true; done
        while ip6tables -w -t nat -D POSTROUTING -j ts-postrouting 2>/dev/null; do true; done
      '';
    };
  };
}
