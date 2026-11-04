{
  services.tailscale = {
    useRoutingFeatures = "client";

    extraSetFlags = ["--exit-node-allow-lan-access"];
  };
}
