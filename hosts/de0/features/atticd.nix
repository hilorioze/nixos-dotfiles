{
  # keep-sorted start
  config,
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets = {
      # keep-sorted start
      "services/atticd/caches/hilorioze/signing-keypair" = {};
      "services/atticd/jwt/private-key" = {};
      "services/atticd/storage/s3/access-key-id" = {};
      "services/atticd/storage/s3/secret-access-key" = {};
      "services/garage/keys/atticd/access-key-id" = {};
      "services/garage/keys/atticd/secret-access-key" = {};
      # keep-sorted end
    };

    templates."config/atticd.env" = {
      content = ''
        # keep-sorted start
        ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."services/atticd/jwt/private-key"}
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."services/atticd/storage/s3/access-key-id"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."services/atticd/storage/s3/secret-access-key"}
        # keep-sorted end
      '';

      # systemd reads `EnvironmentFile=` itself, so ownership doesn't need to be set here
    };
  };

  services = {
    traefik.dynamicConfigOptions.http = {
      routers.atticd = {
        entryPoints = ["https"];
        rule = "Host(`attic.${config.networking.domain}`)";

        service = "atticd";
      };

      services.atticd.loadBalancer.servers = [{url = "http://${config.services.atticd.settings.listen}";}];
    };

    postgresql = {
      authRules = ["local atticd atticd peer"];

      ensureDatabases = ["atticd"];

      ensureUsers = [
        {
          name = "atticd";

          ensureDBOwnership = true;
        }
      ];
    };

    atticd = {
      enable = true;

      environmentFile = config.sops.templates."config/atticd.env".path;

      settings = {
        listen = "127.0.0.1:8081";

        api-endpoint = "https://attic.${config.networking.domain}/";

        garbage-collection.default-retention-period = "30 days";

        # force unix socket; the driver connects via tcp by default
        database.url = "postgresql:///atticd?host=/run/${config.systemd.services.postgresql.serviceConfig.RuntimeDirectory}";

        storage = {
          type = "s3";

          region = outputs.nixosConfigurations.de0.config.services.garage.settings.s3_api.s3_region;
          endpoint = "https://s3.${config.networking.domain}";

          bucket = "attic";
        };
      };
    };
  };

  systemd.services = {
    garage-bootstrap.script = lib.mkAfter ''
      attic_access_key_id=$(< "${config.sops.secrets."services/garage/keys/atticd/access-key-id".path}")
      attic_secret_access_key=$(< "${config.sops.secrets."services/garage/keys/atticd/secret-access-key".path}")

      garage key import "$attic_access_key_id" "$attic_secret_access_key" --yes -n attic || true

      garage bucket create attic || true

      garage bucket allow attic --read --write --key "$attic_access_key_id" || true
    '';

    atticd-bootstrap = {
      wantedBy = ["multi-user.target"];
      after = [
        # keep-sorted start
        "atticd.service"
        "sops-nix.service"
        # keep-sorted end
      ];

      wants = ["sops-nix.service"];
      requires = ["atticd.service"];

      serviceConfig = {
        Type = "oneshot";

        RemainAfterExit = true;
      };

      path = [
        # keep-sorted start
        config.services.atticd.package # provides `atticadm`
        pkgs.attic-client # provides `attic`
        pkgs.curl
        # keep-sorted end
      ];

      script = let
        trustedCacheKeyNames = lib.unique (map (key: builtins.head (lib.splitString ":" key)) (
          config.nix.settings.trusted-public-keys
          ++ config.nix.settings.extra-trusted-public-keys
        ));
      in ''
        # `attic cache configure` always sends `retention_period`; grant both `--configure-cache` and `--configure-cache-retention`
        root_token=$(ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=$(< "${config.sops.secrets."services/atticd/jwt/private-key".path}") \
          atticadm \
          -f ${(pkgs.formats.toml {}).generate "atticd-config.toml" config.services.atticd.settings} \
          \
          make-token \
          \
          --sub root --validity 1m \
          \
          --create-cache '*' \
          --configure-cache '*' --configure-cache-retention '*')

        attic login local http://${config.services.atticd.settings.listen} "$root_token"

        attic cache create hilorioze 2>/dev/null || true

        hilorioze_cache_keypair=$(< "${config.sops.secrets."services/atticd/caches/hilorioze/signing-keypair".path}")
        hilorioze_cache_key_name=''${hilorioze_cache_keypair%%:*}

        set --
        for cache_key_name in ${lib.escapeShellArgs trustedCacheKeyNames}; do
          # don't treat the cache's own key as upstream; attic would skip backfills for it
          if [ "$cache_key_name" != "$hilorioze_cache_key_name" ]; then
            set -- "$@" --upstream-cache-key-name "$cache_key_name"
          fi
        done

        attic cache configure hilorioze --public "$@"

        curl --fail --silent --show-error \
          --request PATCH \
          --header "Authorization: Bearer $root_token" \
          --json "{\"keypair\":{\"Keypair\":\"$hilorioze_cache_keypair\"}}" \
          "http://${config.services.atticd.settings.listen}/_api/v1/cache-config/hilorioze"
      '';
    };
  };
}
