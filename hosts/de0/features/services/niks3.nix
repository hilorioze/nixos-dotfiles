{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  # nixpkgs packages niks3 without its nixos module
  imports = ["${inputs.nixpkgs-unstable.legacyPackages.aarch64-linux.niks3.src}/nix/nixosModules/niks3.nix"];

  sops = {
    secrets = let
      niks3Secret = {
        owner = config.services.niks3.user;

        restartUnits = ["niks3.service"];
      };
    in {
      # keep-sorted start
      "services/niks3/auth/api-token" = niks3Secret;
      "services/niks3/cache/signing-keypair" = niks3Secret;
      "services/niks3/storage/s3/access-key-id" = niks3Secret;
      "services/niks3/storage/s3/secret-access-key" = niks3Secret;
      # keep-sorted end
    };
  };

  services = let
    apiHost = "niks3.${config.networking.domain}";
  in {
    traefik.dynamicConfigOptions.http = {
      routers.niks3 = {
        entryPoints = ["https"];
        rule = "Host(`${apiHost}`)";

        service = "niks3";
      };

      services.niks3.loadBalancer.servers = [{url = "http://${config.services.niks3.httpAddr}";}];
    };

    postgresql = {
      authRules = ["local niks3 niks3 peer"];

      ensureDatabases = ["niks3"];

      ensureUsers = [
        {
          name = "niks3";

          ensureDBOwnership = true;
        }
      ];
    };

    niks3 = {
      enable = true;

      package = pkgs.unstablePkgs.niks3;
      serverPackage = pkgs.unstablePkgs.niks3;

      serverUrl = "https://${apiHost}";

      cacheUrl = "https://nix-cache.${config.networking.domain}";

      gc.olderThan = "336h"; # 14d

      signKeyFiles = [config.sops.secrets."services/niks3/cache/signing-keypair".path];

      # to generate api-token:
      #
      # api_token="$(openssl rand -hex 32)"
      #
      # printf '%s\n' "$api_token"
      apiTokenFile = config.sops.secrets."services/niks3/auth/api-token".path;

      oidc.providers.github = {
        issuer = "https://token.actions.githubusercontent.com";

        audience = "https://niks3.${config.networking.domain}";

        rules = [
          {
            boundSubject = [
              # keep-sorted start
              "repo:hilorioze/cstrike-mod:ref:refs/heads/main"
              "repo:hilorioze@107206970/hilot@1388112599:ref:refs/heads/main"
              "repo:hilorioze@107206970/mud@1434581637:ref:refs/heads/main"
              "repo:hilorioze@107206970/nixos-dotfiles@1247733377:ref:refs/heads/main"
              "repo:hilorioze@107206970/steam-voicechat-fix@1334445192:ref:refs/heads/main"
              # keep-sorted end
            ];

            scopes = ["write"];
          }

          # let main substitute the builds of pull requests it merges; forks get no oidc token
          {
            boundSubject = ["repo:hilorioze@107206970/nixos-dotfiles@1247733377:pull_request"];

            boundClaims = {
              base_ref = ["main"];

              actor = [
                # keep-sorted start
                "hilorioze"
                "renovate[bot]"
                # keep-sorted end
              ];
            };

            scopes = ["write"];
          }
        ];
      };

      database = {
        # force pgx to use the postgresql service socket dir instead of its default host discovery
        connectionString = "postgresql:///niks3?host=/run/${config.systemd.services.postgresql.serviceConfig.RuntimeDirectory}";

        createLocally = false;
      };

      s3 = {
        endpoint = "s3.us-east-005.backblazeb2.com";

        bucket = "nix-cache-hilorioze";

        accessKeyFile = config.sops.secrets."services/niks3/storage/s3/access-key-id".path;
        secretKeyFile = config.sops.secrets."services/niks3/storage/s3/secret-access-key".path;
      };
    };
  };

  systemd.services.niks3 = {
    after = [
      # keep-sorted start
      "postgresql.target"
      "sops-nix.service"
      # keep-sorted end
    ];

    wants = ["sops-nix.service"];
    requires = ["postgresql.target"];

    # keep paths signed by the other substituters out of the cache, nix substitutes them from there; niks3 skips its own key
    environment.NIKS3_UPSTREAM_CACHE_KEY_NAMES = toString (map (key: builtins.head (lib.splitString ":" key)) (
      config.nix.settings.trusted-public-keys
      ++ config.nix.settings.extra-trusted-public-keys
    ));
  };
}
