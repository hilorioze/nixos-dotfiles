{pkgs, ...}: {
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
  ];
}
