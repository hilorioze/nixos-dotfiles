{
  services.networkd-dispatcher = {
    enable = true;

    rules."cloudflare-ddns" = {
      onState = ["routable" "configured"];

      script = ''
        systemctl start cloudflare-ddns.service
      '';
    };
  };
}
