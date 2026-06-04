{
  imports = [
    # keep-sorted start
    ../../common/features/dconf.nix # fixes `ca.desrt.dconf` error (https://github.com/nix-community/home-manager/blob/f384af1bec6423a0d4ba1855917ab948f64e5808/docs/manual/faq/ca-desrt-dconf.md)
    ../../common/features/fluent-bit.nix
    ../../common/features/home-manager.nix
    ../../common/features/node-exporter.nix
    ../../common/features/podman.nix
    # keep-sorted end

    ./containers

    # keep-sorted start
    ./openssh.nix
    ./sops.nix
    ./tailscale.nix
    # keep-sorted end
  ];
}
