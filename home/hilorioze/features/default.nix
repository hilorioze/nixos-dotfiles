{
  imports = [
    # keep-sorted start
    ../../common/features/nix/comma.nix
    ../../common/features/nix/nix-index.nix
    # keep-sorted end

    # keep-sorted start
    ./desktop/stylix.nix
    ./network/ssh.nix
    ./shell/aliases.nix
    ./shell/fastfetch.nix
    ./shell/jq.nix
    ./shell/ripgrep.nix
    ./shell/zsh/zsh.nix
    # keep-sorted end
  ];
}
