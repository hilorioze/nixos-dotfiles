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

    runtimeInputs = with pkgs; [
      # keep-sorted start
      procps
      systemd
      # keep-sorted end
    ];

    excludeShellChecks = (import ../../../../../shared.nix).ignoredShellcheckRules;

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

      # ksystemstats' `nvidia-smi dmon`, coolercontrold's nvml and steam's shader precompilation hold `/dev/nvidia*`, which blocks the gpu's unbind; once it's passed through they come back without it, and after the vm they pick it up again
      case $operation/$suboperation in
        prepare/begin)
          graphicalUsersSystemctl mask --runtime --now plasma-ksystemstats.service
          systemctl stop coolercontrold.service

          # steam queues the killed precompilation again; its workers die with the master, and the name is cut to the kernel's 15 characters
          pkill --exact fossilize_repla && pidwait --exact fossilize_repla
          ;;

        started/begin|release/end)
          graphicalUsersSystemctl unmask --runtime plasma-ksystemstats.service
          graphicalUsersSystemctl restart plasma-ksystemstats.service
          systemctl restart coolercontrold.service
          ;;
      esac
    '';
  });
}
