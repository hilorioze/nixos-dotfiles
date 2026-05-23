{
  imports = [
    # keep-sorted start
    ../../common/features/comma.nix
    ../../common/features/devenv.nix
    ../../common/features/direnv.nix
    ../../common/features/fastfetch.nix
    ../../common/features/gpg-agent-ssh-support.nix
    ../../common/features/gpg-agent.nix
    ../../common/features/gpg.nix
    ../../common/features/nh.nix
    ../../common/features/nix-index.nix
    # keep-sorted end

    # keep-sorted start
    ./git.nix
    ./mcp.nix
    ./nixos-dotfiles-lazy-git-repo.nix
    ./opencode.nix
    ./shell.nix
    ./sops.nix
    ./ssh.nix
    ./stylix.nix
    ./wakatime.nix
    ./zsh.nix
    # keep-sorted end
  ];
}
