{
  imports = [
    # keep-sorted start
    ./nix/gc.nix
    ./security/sudo.nix
    ./shell/zsh.nix
    ./system/boot/tmp.nix
    ./system/coredump.nix
    ./system/journald.nix
    # keep-sorted end
  ];
}
