{
  imports = [
    # keep-sorted start
    ../../common/features/avahi.nix
    ../../common/features/cloudflare-ddns.nix
    ../../common/features/dconf.nix # fixes `ca.desrt.dconf` error (https://github.com/nix-community/home-manager/blob/f384af1bec6423a0d4ba1855917ab948f64e5808/docs/manual/faq/ca-desrt-dconf.md)
    ../../common/features/fluent-bit.nix
    ../../common/features/home-manager.nix
    ../../common/features/netcat-firewall.nix
    ../../common/features/nix.nix
    ../../common/features/node-exporter.nix
    ../../common/features/openssh.nix
    ../../common/features/postgresql.nix
    ../../common/features/systemd-boot.nix
    # keep-sorted end

    # keep-sorted start
    ./bazarr.nix
    ./jellyfin.nix
    ./media-storage.nix
    ./networkd-dispatcher.nix
    ./pinchflat.nix
    ./prowlarr.nix
    ./qbittorrent.nix
    ./radarr.nix
    ./seerr.nix
    ./sonarr.nix
    ./sops.nix
    ./tailscale.nix
    ./time.nix
    ./traefik.nix
    # keep-sorted end
  ];
}
