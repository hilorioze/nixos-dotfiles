{
  imports = [
    # keep-sorted start
    ../../common/features/avahi.nix
    ../../common/features/partition-manager.nix
    ../../common/features/plasma-login-manager.nix
    ../../common/features/plasma.nix
    # keep-sorted end

    # keep-sorted start
    ./auto-login.nix
    ./disable-kde-pim.nix # avoid bundling an entire mariadb installation on the iso
    ./plasma-keyboard.nix
    # keep-sorted end
  ];
}
