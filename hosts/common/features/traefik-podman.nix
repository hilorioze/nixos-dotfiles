{config, ...}: {
  services.traefik = {
    group = config.systemd.sockets.podman.socketConfig.SocketGroup; # ensure traefik can access podman's socket

    staticConfigOptions.providers.docker = {
      endpoint = "unix:///run/podman/podman.sock";

      exposedByDefault = false; # explicit is better than implicit
    };
  };
}
