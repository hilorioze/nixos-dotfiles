{
  imports = [
    # keep-sorted start
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

    # keep-sorted start
    ./containers
    # keep-sorted end

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
