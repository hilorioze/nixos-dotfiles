{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  virtualisation = {
    libvirtd = {
      enable = true;

      hooks.qemu."10-vm-starting" = lib.getExe (pkgs.writeShellApplication {
        name = "vm-starting";

        runtimeInputs = [pkgs.systemd];

        text = ''
          domain=$1
          operation=$2
          suboperation=$3

          userSystemctl() {
            local user=$1
            shift

            systemctl --user --machine=$user@.host "$@"
          }

          activeGraphicalUsersSystemctl() {
            loginctl list-sessions --no-legend --no-pager |
              while read session _ user _; do
                [[
                  $(loginctl show-session $session --property=Active --value) == yes &&
                  $(loginctl show-session $session --property=Class --value) == user &&
                  $(loginctl show-session $session --property=Type --value) =~ ^(wayland|x11)$
                ]] || continue

                userSystemctl $user "$@"
              done
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
              activeGraphicalUsersSystemctl start vm-starting-notification@$domain.service
              ;;

            started/begin|release/end)
              graphicalUsersSystemctl stop vm-starting-notification@$domain.service
              ;;
          esac
        '';
      });

      qemu.vhostUserPackages = [pkgs.virtiofsd];
    };

    spiceUSBRedirection.enable = true;
  };

  systemd.user.services."vm-starting-notification@".serviceConfig = {
    ExecStart = "${lib.getExe pkgs.libnotify} --expire-time=0 --wait %I Starting";

    # `notify-send` only closes `--wait` notifications gracefully on `SIGINT`
    KillSignal = "SIGINT";
  };
}
