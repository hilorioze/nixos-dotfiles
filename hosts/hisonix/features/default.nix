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
    ./disable-kde-pim.nix # Avoid bundling an entire MariaDB installation on the ISO.
    ./plasma-keyboard.nix
    # keep-sorted end
  ];
}
