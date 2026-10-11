{pkgs, ...}: {
  # UPnP discovery sends `M-SEARCH` to the multicast address `239.255.255.250:1900`, and devices answer from their own address and any port
  # conntrack expects the answer from `239.255.255.250:1900`, so it treats the real one as a new inbound connection and the firewall drops it
  # every outgoing `M-SEARCH` stores its source address and port in an ipset for 3 seconds, and inbound UDP to a stored address and port is accepted
  # https://github.com/miniupnp/miniupnp/blob/f33ae48402835b5b93029b1861a32630f9f17d1b/miniupnpc/README#L67-L88
  networking.firewall = {
    extraPackages = [pkgs.ipset];

    extraCommands = ''
      ipset create upnp hash:ip,port timeout 3
      ipset create upnp6 hash:ip,port timeout 3 family inet6

      iptables --append OUTPUT --destination 239.255.255.250/32 --protocol udp --destination-port 1900 --jump SET --add-set upnp src,src --exist
      ip6tables --append OUTPUT --destination ff02::c/128 --protocol udp --destination-port 1900 --jump SET --add-set upnp6 src,src --exist
      ip6tables --append OUTPUT --destination ff05::c/128 --protocol udp --destination-port 1900 --jump SET --add-set upnp6 src,src --exist

      iptables --append nixos-fw --protocol udp --match set --match-set upnp dst,dst --jump nixos-fw-accept
      ip6tables --append nixos-fw --protocol udp --match set --match-set upnp6 dst,dst --jump nixos-fw-accept
    '';

    # `OUTPUT` rules and ipsets live outside `nixos-fw`, so the firewall doesn't flush them on restart or reload
    # an ipset can't be destroyed while a rule references it, and `nixos-fw` outlives a stop
    extraStopCommands = ''
      iptables --delete OUTPUT --destination 239.255.255.250/32 --protocol udp --destination-port 1900 --jump SET --add-set upnp src,src --exist 2>/dev/null || true
      ip6tables --delete OUTPUT --destination ff02::c/128 --protocol udp --destination-port 1900 --jump SET --add-set upnp6 src,src --exist 2>/dev/null || true
      ip6tables --delete OUTPUT --destination ff05::c/128 --protocol udp --destination-port 1900 --jump SET --add-set upnp6 src,src --exist 2>/dev/null || true

      iptables --delete nixos-fw --protocol udp --match set --match-set upnp dst,dst --jump nixos-fw-accept 2>/dev/null || true
      ip6tables --delete nixos-fw --protocol udp --match set --match-set upnp6 dst,dst --jump nixos-fw-accept 2>/dev/null || true

      ipset destroy upnp 2>/dev/null || true
      ipset destroy upnp6 2>/dev/null || true
    '';
  };
}
