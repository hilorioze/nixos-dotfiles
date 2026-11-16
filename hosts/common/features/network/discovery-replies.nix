{pkgs, ...}: {
  # discovery protocols send a query to a broadcast or multicast address, and devices answer from their own address and any port
  # conntrack expects the answer from the broadcast or multicast address, so it treats the real one as a new inbound connection and the firewall drops it
  # every outgoing udp packet to a broadcast or multicast address stores its source address and port in an ipset for 3 seconds, and inbound udp to a stored address and port is accepted
  networking.firewall = {
    extraPackages = [pkgs.ipset];

    extraCommands = ''
      ipset create discovery hash:ip,port timeout 3
      ipset create discovery6 hash:ip,port timeout 3 family inet6

      iptables --append OUTPUT --protocol udp --match addrtype --dst-type BROADCAST --jump SET --add-set discovery src,src --exist
      iptables --append OUTPUT --protocol udp --match addrtype --dst-type MULTICAST --jump SET --add-set discovery src,src --exist
      ip6tables --append OUTPUT --protocol udp --match addrtype --dst-type MULTICAST --jump SET --add-set discovery6 src,src --exist

      iptables --append nixos-fw --protocol udp --match set --match-set discovery dst,dst --jump nixos-fw-accept
      ip6tables --append nixos-fw --protocol udp --match set --match-set discovery6 dst,dst --jump nixos-fw-accept
    '';

    # `OUTPUT` rules and ipsets live outside `nixos-fw`, so the firewall doesn't flush them on restart or reload
    # an ipset can't be destroyed while a rule references it, and `nixos-fw` outlives a stop
    extraStopCommands = ''
      iptables --delete OUTPUT --protocol udp --match addrtype --dst-type BROADCAST --jump SET --add-set discovery src,src --exist 2>/dev/null || true
      iptables --delete OUTPUT --protocol udp --match addrtype --dst-type MULTICAST --jump SET --add-set discovery src,src --exist 2>/dev/null || true
      ip6tables --delete OUTPUT --protocol udp --match addrtype --dst-type MULTICAST --jump SET --add-set discovery6 src,src --exist 2>/dev/null || true

      iptables --delete nixos-fw --protocol udp --match set --match-set discovery dst,dst --jump nixos-fw-accept 2>/dev/null || true
      ip6tables --delete nixos-fw --protocol udp --match set --match-set discovery6 dst,dst --jump nixos-fw-accept 2>/dev/null || true

      ipset destroy discovery 2>/dev/null || true
      ipset destroy discovery6 2>/dev/null || true
    '';
  };
}
