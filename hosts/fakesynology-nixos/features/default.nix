{
  imports = [
    # keep-sorted start
    ../../common/features/avahi.nix
    ../../common/features/cloudflare-ddns.nix
    ../../common/features/fluent-bit.nix
    ../../common/features/home-manager.nix
    ../../common/features/node-exporter.nix
    ../../common/features/openssh.nix
    ../../common/features/systemd-boot.nix
    # keep-sorted end

    # keep-sorted start
    ./networkd-dispatcher.nix
    ./sops.nix
    ./tailscale.nix
    # keep-sorted end
  ];
}
