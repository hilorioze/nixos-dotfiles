{inputs, ...}: {
  imports = [
    # keep-sorted start
    ../../common/features/android/adb.nix
    ../../common/features/audio/pipewire/lowlatency.nix
    ../../common/features/audio/pipewire/pipewire.nix
    ../../common/features/desktop/appimage.nix
    ../../common/features/desktop/flatpak.nix
    ../../common/features/desktop/login/silent-sddm.nix
    ../../common/features/desktop/wayland.nix
    ../../common/features/files/syncthing.nix
    ../../common/features/gaming/gamemode.nix
    ../../common/features/gaming/mangohud.nix
    ../../common/features/gaming/steam.nix
    ../../common/features/hardware/bluetooth.nix
    ../../common/features/hardware/uinput.nix
    ../../common/features/media/gpu-screen-recorder.nix
    ../../common/features/network/avahi.nix
    ../../common/features/network/cloudflare-ddns.nix
    ../../common/features/network/kdeconnect.nix
    ../../common/features/network/netcat.nix
    ../../common/features/network/openssh.nix
    ../../common/features/network/tailscale/client.nix
    ../../common/features/network/tailscale/tailscale.nix
    ../../common/features/network/upnp.nix
    ../../common/features/network/wol.nix
    ../../common/features/nix/home-manager.nix
    ../../common/features/nix/nix.nix
    ../../common/features/security/pcscd.nix
    ../../common/features/security/rtkit.nix
    ../../common/features/security/yubikey-touch-detector.nix
    ../../common/features/storage/kdiskmark.nix
    ../../common/features/storage/partition-manager.nix
    ../../common/features/storage/smartd.nix
    ../../common/features/storage/ventoy.nix
    ../../common/features/system/boot/systemd-boot.nix
    ../../common/features/system/boot/systemd-initrd.nix # required for tpm access in initrd
    ../../common/features/system/locale/i18n.nix
    ../../common/features/system/locale/time.nix
    ../../common/features/system/reclaim-protection.nix
    ../../common/features/system/reisub.nix
    ../../common/features/system/steamos-sysctls.nix
    ../../common/features/system/zswap.nix
    ../../common/features/virtualisation/podman.nix
    # keep-sorted end

    (inputs.import-tree.filterNot (path: path == "/default.nix") ./.) # this file is left out so it doesn't import itself
  ];
}
