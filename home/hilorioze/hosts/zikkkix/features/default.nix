{
  imports = [
    # keep-sorted start
    ../../../../common/features/super-productivity.nix
    ../../../../common/features/trayscale.nix
    ../../../../common/features/yaas.nix
    # keep-sorted end

    # keep-sorted start
    ../../../features/bs-manager.nix
    ../../../features/cinny.nix
    ../../../features/cli-proxy-api.nix
    ../../../features/gpg.nix
    ../../../features/kilocode.nix
    ../../../features/mcp.nix
    ../../../features/niks3.nix
    ../../../features/wakatime.nix
    # keep-sorted end

    # keep-sorted start
    ./git.nix
    ./sops.nix
    # keep-sorted end
  ];
}
