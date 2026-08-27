{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  w10Launcher = pkgs.writeShellApplication {
    name = "w10";

    runtimeInputs = [pkgs.libvirt];

    text = ''
      if [[ $(virsh --connect qemu:///system domstate w10) == "shut off" ]]; then
        virsh --connect qemu:///system start w10
      fi

      exec ${lib.getExe pkgs.looking-glass-client} win:appId=w10
    '';
  };

  w10DesktopEntry = pkgs.makeDesktopItem {
    name = "w10";

    desktopName = "w10";
    icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/distributor-logo-windows.svg";

    exec = lib.getExe w10Launcher;

    categories = ["System"];
  };
in {
  environment.systemPackages = [w10DesktopEntry];

  virtualisation.libvirtd.hooks.qemu."20-w10-passthrough-lifecycle" = lib.getExe (pkgs.writeShellApplication {
    name = "w10-passthrough-lifecycle";

    runtimeInputs = [pkgs.systemd];

    text = ''
      domain=$1
      operation=$2
      suboperation=$3

      [[ $domain == w10 ]] || exit 0

      userSystemctl() {
        local user=$1
        shift

        systemctl --user --machine=$user@.host "$@"
      }

      graphicalUsersSystemctl() {
        loginctl list-users --no-legend --no-pager |
          while read _ user _; do
            userSystemctl $user --quiet is-active graphical-session.target || continue

            userSystemctl $user "$@"
          done
      }

      case $operation/$suboperation in
        prepare/begin)
          graphicalUsersSystemctl mask --runtime --now plasma-ksystemstats.service
          ;;

        started/begin|release/end)
          graphicalUsersSystemctl unmask --runtime plasma-ksystemstats.service
          graphicalUsersSystemctl restart plasma-ksystemstats.service
          ;;
      esac
    '';
  });
}
