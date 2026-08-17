{
  imports = [
    # keep-sorted start
    ../../common/features/comma.nix
    ../../common/features/devenv.nix
    ../../common/features/direnv.nix
    ../../common/features/fastfetch.nix
    ../../common/features/gpg-agent.nix
    ../../common/features/nh.nix
    ../../common/features/nix-index.nix
    # keep-sorted end

    # keep-sorted start
    ./git.nix
    ./nixos-dotfiles-lazy-git-repo.nix
    ./ripgrep.nix
    ./shell.nix
    ./ssh.nix
    ./stylix.nix
    ./zsh.nix
    # keep-sorted end
  ];
}
