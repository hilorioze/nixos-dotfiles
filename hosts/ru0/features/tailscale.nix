{
  imports = [../../common/features/tailscale.nix];

  services.tailscale = {
    useRoutingFeatures = "server";

    extraSetFlags = ["--advertise-exit-node"];
  };
}
