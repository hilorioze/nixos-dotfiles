{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/networkmanager.nix];

  networking.networkmanager.dispatcherScripts = [
    {
      type = "pre-up";

      source = pkgs.writeShellScript "nm-cloudflare-ddns.sh" ''
        case $NM_DISPATCHER_ACTION in
          dhcp4-change|dhcp6-change|up)
            systemctl start cloudflare-ddns.service
            ;;
        esac
      '';
    }

    # keep wifi only as a fallback for the cable: with two addresses on one lan, each answering mdns with a cache flush, resolved on the other lan hosts loops on conflict queries ~10 times a second
    {
      source = pkgs.writeShellScript "nm-wifi-fallback.sh" ''
        case $DEVICE_IFACE:$NM_DISPATCHER_ACTION in
          eno1:up)
            ${lib.getExe' config.networking.networkmanager.package "nmcli"} radio wifi off
            ;;
          eno1:down)
            ${lib.getExe' config.networking.networkmanager.package "nmcli"} radio wifi on
            ;;
        esac
      '';
    }
  ];
}
