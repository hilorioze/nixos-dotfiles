{
  imports = [../../common/features/networkd-dispatcher.nix];

  services.networkd-dispatcher.rules."cloudflare-ddns" = {
    onState = ["routable" "configured"];

    script = ''
      systemctl start cloudflare-ddns.service
    '';
  };
}
