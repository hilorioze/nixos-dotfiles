{
  systemd.services.tailscaled = {
    after = [
      # keep-sorted start
      "headscale.service"
      "traefik.service"
      # keep-sorted end
    ];

    wants = [
      # keep-sorted start
      "headscale.service"
      "traefik.service"
      # keep-sorted end
    ];
  };
}
