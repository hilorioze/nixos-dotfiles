{
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      accessLog = {};

      global = {
        checkNewVersion = false;

        sendAnonymousUsage = false;
      };
    };
  };
}
