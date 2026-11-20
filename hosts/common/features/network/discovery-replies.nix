{lib, ...}: {
  # discovery protocols send a query to a broadcast or multicast address, and devices answer from their own address and any port
  # conntrack expects the answer from the broadcast or multicast address, so it treats the real one as a new inbound connection and the firewall drops it
  # every outgoing udp packet to a broadcast or multicast address stores its source address and port in a set for 3 seconds, and inbound udp to a stored address and port is accepted
  networking = {
    firewall.extraInputRules = ''
      ip daddr . udp dport @discovery accept
      ip6 daddr . udp dport @discovery6 accept
    '';

    # the input rules above read the sets, so they go into the firewall's own table, ahead of its chains
    nftables.tables."nixos-fw".content = lib.mkBefore ''
      set discovery {
        type ipv4_addr . inet_service

        flags dynamic, timeout
        timeout 3s
      }

      set discovery6 {
        type ipv6_addr . inet_service

        flags dynamic, timeout
        timeout 3s
      }

      chain discovery-output {
        type filter hook output priority filter; policy accept;

        meta l4proto udp fib daddr type { broadcast, multicast } update @discovery { ip saddr . udp sport }
        meta l4proto udp fib daddr type multicast update @discovery6 { ip6 saddr . udp sport }
      }
    '';
  };
}
