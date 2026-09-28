{pkgs, ...}: let
  sleepProxyPort = 45800;
in {
  networking.firewall.allowedUDPPorts = [sleepProxyPort];

  environment.etc."desomnia/monitor.xml".source = pkgs.replaceVars ./desomnia-monitor-proxy.xml {
    sleepProxyPort = toString sleepProxyPort;
  };
}
