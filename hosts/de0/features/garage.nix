{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets = {
      # to generate access-key-id and secret-access-key:
      #
      # access_key_id="GK$(, openssl rand -hex 12)"
      # secret_access_key="$(, openssl rand -hex 32)"
      #
      # printf '%s\n' "$access_key_id"
      # printf '%s\n' "$secret_access_key"

      # keep-sorted start
      "services/garage/keys/hilorioze/access-key-id" = {};
      "services/garage/keys/hilorioze/secret-access-key" = {};
      "services/garage/rpc/secret" = {}; # garage requires `rpc_secret` for its RPC layer, even on a single-node deployment
      # keep-sorted end
    };

    templates."config/garage.env" = {
      content = ''
        GARAGE_RPC_SECRET=${config.sops.placeholder."services/garage/rpc/secret"}
      '';

      # systemd reads `EnvironmentFile=` itself, so ownership doesn't need to be set here
    };
  };

  services = {
    traefik.dynamicConfigOptions.http = {
      routers = {
        garage = {
          entryPoints = ["https"];
          rule = "Host(`s3.${config.networking.domain}`)";

          service = "garage";
        };

        garage-admin = {
          entryPoints = ["https"];
          rule = "Host(`garage-admin.${config.networking.fqdn}`)";

          service = "garage-admin";
        };
      };

      services = {
        garage.loadBalancer.servers = [{url = "http://${config.services.garage.settings.s3_api.api_bind_addr}";}];

        garage-admin.loadBalancer.servers = [{url = "http://${config.services.garage.settings.admin.api_bind_addr}";}];
      };
    };

    garage = {
      enable = true;

      package = pkgs.garage_2;

      environmentFile = config.sops.templates."config/garage.env".path;

      settings = {
        replication_factor = 1;

        compression_level = "none";

        rpc_bind_addr = "127.0.0.1:3901"; # needed for internal coordination even on single-node setups

        s3_api = {
          s3_region = "garage";

          api_bind_addr = "127.0.0.1:3900";
        };

        admin = {
          api_bind_addr = "127.0.0.1:3903";

          metrics_require_token = true; # since we're keeping the admin endpoint public for cross-host gatus health checks, close `/metrics` to prevent reconnaissance
        };
      };
    };
  };

  systemd.services.garage-bootstrap = {
    wantedBy = ["multi-user.target"];
    after = [
      # keep-sorted start
      "garage.service"
      "sops-nix.service"
      # keep-sorted end
    ];

    wants = ["sops-nix.service"];
    requires = ["garage.service"];

    serviceConfig = {
      Type = "oneshot";

      EnvironmentFile = config.services.garage.environmentFile;

      RemainAfterExit = true;
    };

    path = [config.services.garage.package];

    script = ''
      for _ in {1..60}; do garage status &>/dev/null && break; sleep 1; done

      garage layout assign -z de0 -c 100GiB "$(garage node id -q)"

      layout_show="$(garage layout show)"
      if grep -q '^==== STAGED ROLE CHANGES ====$' <<<"$layout_show"; then
        current_version="$(grep -oP 'Current cluster layout version: \K\d+' <<<"$layout_show")"
        garage layout apply --version "$((current_version + 1))"
      fi

      hilorioze_access_key_id=$(<"${config.sops.secrets."services/garage/keys/hilorioze/access-key-id".path}")
      hilorioze_secret_access_key=$(<"${config.sops.secrets."services/garage/keys/hilorioze/secret-access-key".path}")

      garage key import "$hilorioze_access_key_id" "$hilorioze_secret_access_key" --yes -n hilorioze || true

      garage key allow "$hilorioze_access_key_id" --create-bucket
    '';
  };
}
