{
  imports = [
    # keep-sorted start
    ../../common/features/fail2ban.nix
    ../../common/features/fluent-bit.nix
    ../../common/features/home-manager.nix
    ../../common/features/node-exporter.nix
    ../../common/features/openssh.nix
    ../../common/features/podman.nix
    ../../common/features/traefik-podman.nix
    ../../common/features/whoami.nix
    # keep-sorted end

    ./containers

    # keep-sorted start
    ./acme.nix
    ./archisteamfarm.nix
    ./headscale.nix
    ./mailserver.nix
    ./openldap.nix
    ./pdns-recursor.nix
    ./sops.nix
    ./tailscale.nix
    ./traefik.nix
    # keep-sorted end
  ];
}
