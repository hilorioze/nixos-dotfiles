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
      "services/garage/keys/niks3/access-key-id" = {};
      "services/garage/keys/niks3/secret-access-key" = {};
      "services/niks3/auth/api-token".owner = config.services.niks3.user;
      "services/niks3/cache/signing-keypair".owner = config.services.niks3.user;
      "services/niks3/storage/s3/access-key-id".owner = config.services.niks3.user;
      "services/niks3/storage/s3/secret-access-key".owner = config.services.niks3.user;
      # keep-sorted end
    };
  };

  services = {
    traefik.dynamicConfigOptions.http = {
      routers = {
        nix-cache = {
          entryPoints = ["https"];
          rule = "Host(`nix-cache.${config.networking.domain}`)";

          service = "garage-web";
        };

        niks3 = {
          entryPoints = ["https"];
          rule = "Host(`niks3.${config.networking.domain}`)";

          service = "niks3";
        };
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

        audience = "https://niks3.hilorioze.com";

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
        endpoint = "s3.${config.networking.domain}";
        region = config.services.garage.settings.s3_api.s3_region;

        bucket = "nix-cache";

        accessKeyFile = config.sops.secrets."services/niks3/storage/s3/access-key-id".path;
        secretKeyFile = config.sops.secrets."services/niks3/storage/s3/secret-access-key".path;
      };
    };
  };

  systemd.services = {
    garage-bootstrap.script = ''
      niks3_access_key_id=$(<${config.sops.secrets."services/garage/keys/niks3/access-key-id".path})
      niks3_secret_access_key=$(<${config.sops.secrets."services/garage/keys/niks3/secret-access-key".path})

      garage key import $niks3_access_key_id $niks3_secret_access_key --yes -n niks3 || true

      garage bucket create nix-cache || true
      garage bucket allow nix-cache --read --write --key $niks3_access_key_id

      garage bucket alias nix-cache nix-cache.${config.networking.domain}
      garage bucket website --allow nix-cache
    '';

    niks3 = {
      after = [
        # keep-sorted start
        "garage-bootstrap.service"
        "postgresql.service"
        "sops-nix.service"
        # keep-sorted end
      ];

      wants = ["sops-nix.service"];
      requires = [
        # keep-sorted start
        "garage-bootstrap.service"
        "postgresql.service"
        # keep-sorted end
      ];
    };
  };
}
