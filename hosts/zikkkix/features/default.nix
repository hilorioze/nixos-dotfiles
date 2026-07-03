{
  imports = [
    # keep-sorted start
    ../../common/features/appimage.nix
    ../../common/features/avahi.nix
    ../../common/features/bluetooth.nix
    ../../common/features/gamemode.nix
    ../../common/features/home-manager.nix
    ../../common/features/netcat-firewall.nix
    ../../common/features/networkmanager.nix
    ../../common/features/nix.nix
    ../../common/features/openssh.nix
    ../../common/features/pipewire-lowlatency.nix
    ../../common/features/pipewire.nix
    ../../common/features/plasma-login-manager.nix
    ../../common/features/platform-optimizations.nix
    ../../common/features/reisub.nix
    ../../common/features/rtkit.nix
    ../../common/features/systemd-boot.nix
    ../../common/features/tailscale.nix
    ../../common/features/wayland.nix
    # keep-sorted end

    # keep-sorted start
    ./mt7927.nix
    ./plasma.nix
    ./sops.nix
    # keep-sorted end
  ];
}
