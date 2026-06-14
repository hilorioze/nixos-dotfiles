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

          http3 = {};
        };
        # keep-sorted end
      };
    };
  };
}
