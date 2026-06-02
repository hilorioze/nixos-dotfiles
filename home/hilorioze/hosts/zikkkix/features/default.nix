{
  imports = [
    # keep-sorted start
    ../../../../common/features/bs-manager.nix
    ../../../../common/features/super-productivity.nix
    ../../../../common/features/trayscale.nix
    ../../../../common/features/yaas.nix
    # keep-sorted end

    # keep-sorted start
    ../../../features/cli-proxy-api.nix
    ../../../features/gpg.nix
    # keep-sorted end

    ./sops.nix
  ];
}
