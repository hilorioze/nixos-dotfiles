{
  imports = [
    # keep-sorted start
    ./network/nftables.nix
    ./nix/gc.nix
    ./security/sudo.nix
    ./shell/zsh.nix
    ./system/boot/tmp.nix
    ./system/coredump.nix
    ./system/journald.nix
    # keep-sorted end
  ];
}
