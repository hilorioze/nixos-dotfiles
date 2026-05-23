{
  imports = [../../common/features/tailscale.nix];

  services.tailscale.useRoutingFeatures = "client";
}
