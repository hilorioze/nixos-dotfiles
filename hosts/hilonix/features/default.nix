{
  imports = [
    # keep-sorted start
    ../../common/features/adb.nix
    ../../common/features/appimage.nix
    ../../common/features/avahi.nix
    ../../common/features/bluetooth.nix
    ../../common/features/cloudflare-ddns.nix
    ../../common/features/firejail.nix
    ../../common/features/flatpak.nix
    ../../common/features/gamemode.nix
    ../../common/features/home-manager.nix
    ../../common/features/kdeconnect-firewall.nix
    ../../common/features/kdiskmark.nix
    ../../common/features/kexec-reboot.nix
    ../../common/features/kexec.nix
    ../../common/features/libvirtd.nix
    ../../common/features/mangohud.nix
    ../../common/features/networkmanager-wol.nix
    ../../common/features/openssh.nix
    ../../common/features/packettracer9.nix
    ../../common/features/partition-manager.nix
    ../../common/features/pipewire-lowlatency.nix
    ../../common/features/pipewire.nix
    ../../common/features/platform-optimizations.nix
    ../../common/features/podman.nix
    ../../common/features/polychromatic.nix
    ../../common/features/reisub.nix
    ../../common/features/rtkit.nix
    ../../common/features/steam.nix
    ../../common/features/syncthing-firewall.nix
    ../../common/features/systemd-boot.nix
    ../../common/features/systemd-initrd.nix # required for TPM access in initrd
    ../../common/features/wayland.nix
    ../../common/features/wine.nix
    ../../common/features/wireshark-usbmon.nix
    ../../common/features/wireshark.nix
    ../../common/features/wivrn.nix
    # keep-sorted end

    # keep-sorted start
    ./coolercontrol.nix
    ./i18n.nix
    ./networkmanager.nix
    ./nix-ld.nix
    ./openrazer.nix
    ./plasma.nix
    ./sddm.nix
    ./silent-sddm.nix
    ./sops.nix
    ./stylix.nix
    ./tailscale.nix
    ./time.nix
    # keep-sorted end
  ];
}
