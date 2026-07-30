{
  imports = [
    # keep-sorted start
    ../../common/features/dconf.nix # fixes `ca.desrt.dconf` error (https://github.com/nix-community/home-manager/blob/f384af1bec6423a0d4ba1855917ab948f64e5808/docs/manual/faq/ca-desrt-dconf.md)
    ../../common/features/fail2ban.nix
    ../../common/features/fluent-bit.nix
    ../../common/features/home-manager.nix
    ../../common/features/netcat-firewall.nix
    ../../common/features/nix.nix
    ../../common/features/node-exporter.nix
    ../../common/features/openssh.nix
    ../../common/features/podman.nix
    ../../common/features/sslh-tailscale.nix
    ../../common/features/sslh.nix
    ../../common/features/tailscale-server.nix
    ../../common/features/tailscale.nix
    ../../common/features/traefik-podman.nix
    ../../common/features/whoami.nix
    # keep-sorted end

    ./containers

    # keep-sorted start
    ./acme.nix
    ./archisteamfarm.nix
    ./cex-proxy.nix
    ./factorio.nix
    ./fakesynology-proxy.nix
    ./headscale.nix
    ./mailserver.nix
    ./openldap.nix
    ./pdns-recursor.nix
    ./sops.nix
    ./tailscale.nix
    ./traefik.nix
    # keep-sorted end
  ];
}
