{
  imports = [
    # keep-sorted start
    ./nix/nh.nix
    ./nix/nix-monitored.nix
    ./security/sudo.nix
    ./shell/zsh.nix
    ./system/boot/tmp.nix
    ./system/coredump.nix
    ./system/journald.nix
    # keep-sorted end
  ];
}
