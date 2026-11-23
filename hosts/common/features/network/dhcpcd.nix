{
  networking.dhcpcd.persistent = true; # keep addresses and routes while `dhcpcd` restarts in a switch, so tailscale, dns and the deploy connection survive it
}
