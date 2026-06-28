{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  networking.firewall.allowedTCPPorts = [8501];

  sops.secrets."services/ncps/cache/signing-key".owner = config.systemd.services.ncps.serviceConfig.User;

  services = {
    postgresql = {
      authRules = ["local ncps ncps peer"];

      ensureDatabases = ["ncps"];

      ensureUsers = [
        {
          name = "ncps";

          ensureDBOwnership = true;
        }
      ];
    };

    ncps = {
      enable = true;

      server.addr = "127.0.0.1:8502";

      cache = {
        hostName = "192.168.1.101";

        secretKeyPath = config.sops.secrets."services/ncps/cache/signing-key".path;

        # no explicit `host` is needed; `pgx` checks `/var/run/postgresql`, which is `/run/postgresql` on NixOS
        databaseURL = "postgresql:///ncps";

        upstream = let
          inherit ((import ../../../flake.nix).nixConfig) extra-substituters extra-trusted-public-keys;
        in {
          # keep `cache.nixos.org` explicit; `ncps` doesn't add it by default
          urls = ["https://cache.nixos.org"] ++ extra-substituters;

          publicKeys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="] ++ extra-trusted-public-keys;
        };

        maxSize = "100G";

        lru.schedule = "0 14 * * 0"; # run the LRU sweep weekly at 2 PM
      };
    };

    traefik = {
      staticConfigOptions.entryPoints.ncps.address = ":8501";

      dynamicConfigOptions.http = {
        routers.ncps = {
          entryPoints = ["ncps"];
          rule = "PathPrefix(`/`)"; # match every request

          service = "ncps";
        };

        services.ncps.loadBalancer.servers = [{url = "http://127.0.0.1:${(lib.last (lib.splitString ":" config.services.ncps.server.addr))}";}];
      };
    };
  };

  systemd.services.ncps = {
    after = [
      # keep-sorted start
      "postgresql.target"
      "sops-nix.service"
      # keep-sorted end
    ];

    wants = ["sops-nix.service"];
    requires = ["postgresql.target"];
  };
}
