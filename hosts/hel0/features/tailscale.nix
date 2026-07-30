{
  imports = [../../common/features/tailscale.nix];

  services.tailscale = {
    useRoutingFeatures = "server";

    extraSetFlags = ["--advertise-exit-node"];
  };

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
