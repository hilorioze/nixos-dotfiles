{
  services.networkd-dispatcher = {
    enable = true;

    rules."cloudflare-ddns" = {
      onState = [
        # keep-sorted start
        "configured"
        "routable"
        # keep-sorted end
      ];

      script = "systemctl start cloudflare-ddns.service";
    };
  };
}
