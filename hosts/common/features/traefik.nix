{
  networking.firewall = {
    allowedTCPPorts = [
      # keep-sorted start numeric=yes
      80
      443
      # keep-sorted end
    ];

    allowedUDPPorts = [443];
  };

  services.traefik = {
    enable = true;

    dynamicConfigOptions.http.middlewares.redirect-to-https.redirectScheme = {
      scheme = "https";

      permanent = true;
    };

    staticConfigOptions = {
      accessLog = {};

      global = {
        checkNewVersion = false;

        sendAnonymousUsage = false;
      };

      entryPoints = {
        # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=address\s*=\s*[^;]*?:(\d+)
        http.address = ":80";

        https = {
          address = ":443";

          # trust `X-Forwarded-*` and `X-Real-Ip` headers from cloudflare edge IPs
          # https://www.cloudflare.com/ips-v4 https://www.cloudflare.com/ips-v6
          forwardedHeaders.trustedIPs = [
            # keep-sorted start
            "103.21.244.0/22"
            "103.22.200.0/22"
            "103.31.4.0/22"
            "104.16.0.0/13"
            "104.24.0.0/14"
            "108.162.192.0/18"
            "131.0.72.0/22"
            "141.101.64.0/18"
            "162.158.0.0/15"
            "172.64.0.0/13"
            "173.245.48.0/20"
            "188.114.96.0/20"
            "190.93.240.0/20"
            "197.234.240.0/22"
            "198.41.128.0/17"
            "2400:cb00::/32"
            "2405:8100::/32"
            "2405:b500::/32"
            "2606:4700::/32"
            "2803:f800::/32"
            "2a06:98c0::/29"
            "2c0f:f248::/32"
            # keep-sorted end
          ];

          http3 = {};
        };
        # keep-sorted end
      };
    };
  };
}
