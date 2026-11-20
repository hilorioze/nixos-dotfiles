{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: let
  image = "ghcr.io/hilorioze/goldsrc-proxy-rs@sha256:2c9176d9650dfccaac3a131e7f4c064f2b6e48af15d1b08640add00e0c865f03"; # 1dcaa6d

  proxies = [
    # keep-sorted start block=yes newline_separated=yes
    {
      upstreamHost = "46.174.48.101";
      upstreamPort = 27015;

      downstreamPort = 27015;
    }

    {
      upstreamHost = "46.174.48.32";
      upstreamPort = 28255;

      downstreamPort = 28255;
    }

    {
      upstreamHost = "46.174.52.2";
      upstreamPort = 27256;

      downstreamPort = 27256;
    }

    {
      upstreamHost = "46.174.52.97";
      upstreamPort = 27015;

      downstreamPort = 27016;
    }
    # keep-sorted end
  ];

  containersList =
    map (proxy: {
      "goldsrc-proxy-rs-${toString proxy.downstreamPort}" = {
        inherit image;

        login = {
          registry = "ghcr.io";

          username = "hilorioze";
          passwordFile = config.sops.secrets."credentials/ghcr/hilorioze/pull/token".path;
        };

        environment = {
          LISTEN = "0.0.0.0:${toString proxy.downstreamPort}";
          UPSTREAM = "${proxy.upstreamHost}:${toString proxy.upstreamPort}";

          RUST_LOG = "debug";
        };

        extraOptions = ["--network=host"];
      };
    })
    proxies;
in {
  sops.secrets."credentials/ghcr/hilorioze/pull/token" = {};

  networking = {
    firewall.allowedUDPPorts = map (proxy: proxy.downstreamPort) proxies;

    # players failed to connect through the proxies while conntrack tracked their traffic
    nftables.tables.goldsrc-proxy-rs = let
      downstreamPorts = "{ ${lib.concatMapStringsSep ", " (proxy: toString proxy.downstreamPort) proxies} }";
    in {
      family = "inet";

      content = ''
        chain prerouting {
          type filter hook prerouting priority raw; policy accept;

          udp dport ${downstreamPorts} notrack
        }

        chain output {
          type filter hook output priority raw; policy accept;

          udp sport ${downstreamPorts} notrack
        }
      '';
    };
  };

  virtualisation.oci-containers.containers = lib.attrsets.mergeAttrsList containersList;
}
