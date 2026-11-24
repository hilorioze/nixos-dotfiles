# the middlewares of a novnc viewer served by websockify
{
  services.traefik.dynamicConfigOptions.http.middlewares = {
    # novnc has no index page; the viewer connects on its own and resizes the virtual output to the window
    novnc-viewer.redirectRegex = {
      regex = "^https://([^/]+)/$";
      replacement = "https://\${1}/vnc.html?autoconnect=true&reconnect=true&resize=remote";
    };

    # websockify upgrades a request on any path to the vnc connection, which has no password of its own, so the unauthenticated check must never carry an upgrade
    no-upgrade.headers.customRequestHeaders.Upgrade = ""; # an empty value removes the header

    novnc-health.replacePath.path = "/vnc.html";
  };
}
