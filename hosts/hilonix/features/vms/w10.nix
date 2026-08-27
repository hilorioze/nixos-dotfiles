{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
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
