{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: let
  image = "ghcr.io/hilorioze/goldsrc-proxy-rs@sha256:2c9176d9650dfccaac3a131e7f4c064f2b6e48af15d1b08640add00e0c865f03"; # 1dcaa6d

  proxies = [
    {
      ip = "46.174.48.101";
      port = 27015;
    }
    {
      ip = "46.174.48.32";
      port = 28255;
    }
  ];

  containersList =
    map (proxy: {
      "goldsrc-proxy-rs-${toString proxy.port}" = {
        inherit image;
        login = {
          registry = "ghcr.io";
          username = "hilorioze";
          passwordFile = config.sops.secrets."credentials/ghcr/hilorioze/pull/token".path;
        };
        environment = {
          "LISTEN" = "0.0.0.0:${toString proxy.port}";
          "UPSTREAM" = "${proxy.ip}:${toString proxy.port}";
          "RUST_LOG" = "debug";
        };
        extraOptions = ["--network=host"];
      };
    })
    proxies;
in {
  sops.secrets."credentials/ghcr/hilorioze/pull/token" = {};

  networking.firewall = {
    allowedUDPPorts = map (proxy: proxy.port) proxies;

    extraCommands = lib.mkAfter (lib.concatMapStringsSep "\n\n" (proxy: ''
        iptables -t raw -A PREROUTING -p udp --dport ${toString proxy.port} -j NOTRACK
        iptables -t raw -A OUTPUT -p udp --sport ${toString proxy.port} -j NOTRACK
        iptables -I INPUT 1 -p udp --dport ${toString proxy.port} -m conntrack --ctstate UNTRACKED -j ACCEPT
        iptables -I OUTPUT 1 -p udp --sport ${toString proxy.port} -m conntrack --ctstate UNTRACKED -j ACCEPT
      '')
      proxies);

    extraStopCommands = lib.mkAfter (lib.concatMapStringsSep "\n\n" (proxy: ''
        iptables -t raw -D PREROUTING -p udp --dport ${toString proxy.port} -j NOTRACK 2>/dev/null || true
        iptables -t raw -D OUTPUT -p udp --sport ${toString proxy.port} -j NOTRACK 2>/dev/null || true
        iptables -D INPUT -p udp --dport ${toString proxy.port} -m conntrack --ctstate UNTRACKED -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -p udp --sport ${toString proxy.port} -m conntrack --ctstate UNTRACKED -j ACCEPT 2>/dev/null || true
      '')
      proxies);
  };

  virtualisation.oci-containers.containers = lib.attrsets.mergeAttrsList containersList;
}
