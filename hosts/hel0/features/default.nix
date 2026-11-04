{inputs, ...}: {
  imports = [
    # keep-sorted start
    ../../common/features/desktop/dconf.nix # fixes `ca.desrt.dconf` error (https://github.com/nix-community/home-manager/blob/f384af1bec6423a0d4ba1855917ab948f64e5808/docs/manual/faq/ca-desrt-dconf.md)
    ../../common/features/network/netcat.nix
    ../../common/features/network/openssh.nix
    ../../common/features/network/tailscale/server.nix
    ../../common/features/network/tailscale/tailscale.nix
    ../../common/features/nix/home-manager.nix
    ../../common/features/nix/nix.nix
    ../../common/features/security/fail2ban.nix
    ../../common/features/services/monitoring/fluent-bit.nix
    ../../common/features/services/monitoring/node-exporter.nix
    ../../common/features/services/web/traefik/podman.nix
    ../../common/features/services/web/traefik/traefik.nix
    ../../common/features/services/web/whoami.nix
    ../../common/features/virtualisation/podman.nix
    # keep-sorted end

    (inputs.import-tree.filterNot (path: path == "/default.nix") ./.) # this file is left out so it doesn't import itself
  ];
}
