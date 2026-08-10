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
    ../../../features/bs-manager.nix
    ../../../features/cinny.nix
    ../../../features/codex-desktop.nix
    ../../../features/codex.nix
    ../../../features/email.nix
    ../../../features/gpg.nix
    ../../../features/lazyvim.nix
    ../../../features/mcp.nix
    ../../../features/niks3.nix
    ../../../features/plasma.nix
    ../../../features/thunderbird.nix
    ../../../features/wakatime.nix
    ../../../features/wl-clipboard.nix
    # keep-sorted end

    # keep-sorted start
    ./git.nix
    ./gpg-agent.nix
    ./sops.nix
    # keep-sorted end
  ];
}
