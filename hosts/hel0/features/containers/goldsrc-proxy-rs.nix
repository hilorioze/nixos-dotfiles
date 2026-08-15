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
        iptables --table raw --append PREROUTING --protocol udp --dport ${toString proxy.port} --jump NOTRACK
        iptables --table raw --append OUTPUT --protocol udp --sport ${toString proxy.port} --jump NOTRACK
      '')
      proxies);

    extraStopCommands = lib.mkAfter (lib.concatMapStringsSep "\n\n" (proxy: ''
        iptables --table raw --delete PREROUTING --protocol udp --dport ${toString proxy.port} --jump NOTRACK 2>/dev/null || true
        iptables --table raw --delete OUTPUT --protocol udp --sport ${toString proxy.port} --jump NOTRACK 2>/dev/null || true
      '')
      proxies);
  };

  virtualisation.oci-containers.containers = lib.attrsets.mergeAttrsList containersList;
}
