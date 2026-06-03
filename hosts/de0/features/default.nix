{
  imports = [
    # keep-sorted start
    ../../common/features/dconf.nix # fixes `ca.desrt.dconf` error (https://github.com/nix-community/home-manager/blob/f384af1bec6423a0d4ba1855917ab948f64e5808/docs/manual/faq/ca-desrt-dconf.md)
    ../../common/features/fail2ban.nix
    ../../common/features/fluent-bit.nix
    ../../common/features/home-manager.nix
    ../../common/features/nix-ld.nix
    ../../common/features/node-exporter.nix
    ../../common/features/podman.nix
    ../../common/features/postgresql.nix
    ../../common/features/rabbitmq.nix
    ../../common/features/redis.nix
    ../../common/features/systemd-boot.nix
    ../../common/features/traefik-podman.nix
    ../../common/features/whoami.nix
    # keep-sorted end

    ./containers

    # keep-sorted start
    ./alertmanager.nix
    ./atticd.nix
    ./garage.nix
    ./gatus.nix
    ./grafana.nix
    ./hermes-agent.nix
    ./loki.nix
    ./openssh.nix
    ./prometheus.nix
    ./sops.nix
    ./tailscale.nix
    ./traefik.nix
    # keep-sorted end
  ];
}
