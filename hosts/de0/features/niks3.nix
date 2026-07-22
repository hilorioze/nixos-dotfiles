{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.niks3.nixosModules.niks3];

  sops = {
    secrets = {
      # keep-sorted start
      "services/niks3/auth/api-token".owner = config.services.niks3.user;
      "services/niks3/cache/signing-keypair".owner = config.services.niks3.user;
      "services/niks3/storage/s3/access-key-id".owner = config.services.niks3.user;
      "services/niks3/storage/s3/secret-access-key".owner = config.services.niks3.user;
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

      serverUrl = "https://${apiHost}";

      cacheUrl = "https://nix-cache.${config.networking.domain}";

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

        boundSubject = [
          # keep-sorted start
          "repo:hilorioze/cstrike-mod:ref:refs/heads/main"
          "repo:hilorioze/nixos-dotfiles:ref:refs/heads/main"
          # keep-sorted end
        ];
      };

      database = {
        # force `pgx` to use the postgresql service socket dir instead of its default host discovery
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
  };
}
