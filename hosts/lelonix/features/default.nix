{
  imports = [
    # keep-sorted start
    ../../common/features/adb.nix
    ../../common/features/appimage.nix
    ../../common/features/avahi.nix
    ../../common/features/bluetooth.nix
    ../../common/features/coolercontrol.nix
    ../../common/features/flatpak.nix
    ../../common/features/gamemode.nix
    ../../common/features/home-manager.nix
    ../../common/features/kdeconnect-firewall.nix
    ../../common/features/kdiskmark.nix
    ../../common/features/lenovo-legion-app.nix
    ../../common/features/mangohud.nix
    ../../common/features/netcat-firewall.nix
    ../../common/features/networkmanager-wol.nix
    ../../common/features/nix.nix
    ../../common/features/openssh.nix
    ../../common/features/partition-manager.nix
    ../../common/features/pcscd.nix
    ../../common/features/pipewire-lowlatency.nix
    ../../common/features/pipewire.nix
    ../../common/features/plasmavantage.nix
    ../../common/features/platform-optimizations.nix
    ../../common/features/reisub.nix
    ../../common/features/rtkit.nix
    ../../common/features/steam.nix
    ../../common/features/syncthing-firewall.nix
    ../../common/features/systemd-boot.nix
    ../../common/features/systemd-initrd.nix # required for TPM access in initrd
    ../../common/features/tailscale-client.nix
    ../../common/features/tailscale.nix
    ../../common/features/wayland.nix
    ../../common/features/wine.nix
    # keep-sorted end

    # keep-sorted start
    ./automatic-timezoned.nix
    ./i18n.nix
    ./networkmanager.nix
    ./nix-ld.nix
    ./plasma.nix
    ./sddm.nix
    ./silent-sddm.nix
    ./sops.nix
    ./stylix.nix
    # keep-sorted end
  ];
}
