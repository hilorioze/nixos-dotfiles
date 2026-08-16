{
  imports = [
    # keep-sorted start
    ../../../../common/features/super-productivity.nix
    ../../../../common/features/trayscale.nix
    ../../../../common/features/yaas.nix
    # keep-sorted end

    # keep-sorted start
    ../../../features/antigravity-cli.nix
    ../../../features/atuin.nix
    ../../../features/bambu-studio.nix
    ../../../features/bs-manager.nix
    ../../../features/cinny.nix
    ../../../features/codex-desktop.nix
    ../../../features/codex.nix
    ../../../features/email.nix
    ../../../features/git-hardware-signing.nix
    ../../../features/gpg.nix
    ../../../features/lazygit.nix
    ../../../features/lazyvim.nix
    ../../../features/mcp.nix
    ../../../features/niks3.nix
    ../../../features/plasma.nix
    ../../../features/ssh-agent.nix
    ../../../features/ssh-fido2.nix
    ../../../features/thunderbird.nix
    ../../../features/wakatime.nix
    ../../../features/wl-clipboard.nix
    # keep-sorted end

    ./sops.nix
  ];
}
