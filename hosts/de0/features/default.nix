{
  imports = [
    # keep-sorted start
    ../../common/features/dconf.nix # fixes `ca.desrt.dconf` error (https://github.com/nix-community/home-manager/blob/f384af1bec6423a0d4ba1855917ab948f64e5808/docs/manual/faq/ca-desrt-dconf.md)
    ../../common/features/fail2ban.nix
    ../../common/features/fluent-bit.nix
    ../../common/features/home-manager.nix
    ../../common/features/netcat-firewall.nix
    ../../common/features/nix-ld.nix
    ../../common/features/nix.nix
    ../../common/features/node-exporter.nix
    ../../common/features/openssh.nix
    ../../common/features/postgresql.nix
    ../../common/features/rabbitmq.nix
    ../../common/features/redis.nix
    ../../common/features/sslh.nix
    ../../common/features/systemd-boot.nix
    ../../common/features/traefik-podman.nix
    ../../common/features/whoami.nix
    # keep-sorted end

    ./containers

    # keep-sorted start
    ./alertmanager.nix
    ./fakesynology-proxy.nix
    ./gatus.nix
    ./grafana.nix
    ./loki.nix
    ./niks3.nix
    ./podman-exporter.nix
    ./podman.nix
    ./prometheus.nix
    ./sops.nix
    ./tailscale.nix
    ./traefik.nix
    # keep-sorted end
  ];
}
