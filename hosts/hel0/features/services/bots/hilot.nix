{
  # keep-sorted start
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: let
  # one `hilot-bot` per telegram account, each with its own http port; the account comes from the session string
  botPorts = {
    # keep-sorted start
    hilorioze = 9104;
    qpw = 9101;
    # keep-sorted end
  };

  # the port of every service's `/healthz` and `/metrics`
  httpPorts =
    lib.mapAttrs' (name: port: lib.nameValuePair "hilot-bot-${name}" port) botPorts
    // {
      # keep-sorted start
      hilot-downloader = 9102;
      hilot-transcoder = 9103;
      # keep-sorted end
    };
in {
  sops = {
    secrets = let
      # garage-setup imports the key; the services require it and restart with it
      s3Secret.restartUnits = ["garage-setup.service"];
    in
      lib.mkMerge [
        {
          # printf '["%s"]\n' $(, openssl rand -base64 32 | tr '+/' '-_')
          "services/hilot/cookie-keys".restartUnits = ["hilot-downloader.service"];

          # token=$(, openssl rand -hex 32); printf 'token: %s\nhashed-token: %s\n' $token $(, mkpasswd --method=bcrypt --rounds=10 $token)
          "services/hilot/nats-token".restartUnits = lib.mkMerge [
            [
              # keep-sorted start
              "hilot-downloader.service"
              "hilot-transcoder.service"
              # keep-sorted end
            ]

            (lib.mapAttrsToList (name: _: "hilot-bot-${name}.service") botPorts)
          ];

          # , mkpasswd --method=bcrypt --rounds=10
          "services/nats/tokens/hilot/hashed-token" = {};

          # password=$(, openssl rand -hex 32); printf 'password: %s\nhashed-password: %s\n' $password $(, openssl passwd -1 $password)
          "services/hilot/proxy-password" = {};

          # printf 'access-key-id: GK%s\nsecret-access-key: %s\n' $(, openssl rand -hex 12) $(, openssl rand -hex 32)
          "services/hilot/s3-access-key-id" = s3Secret;
          "services/hilot/s3-secret-access-key" = s3Secret;
        }

        # to generate a session-string, in the hilot repository execute `hilot-login`
        (lib.mapAttrs' (name: _: lib.nameValuePair "services/hilot/accounts/${name}/session-string" {restartUnits = ["hilot-bot-${name}.service"];}) botPorts)
      ];

    templates."services/hilot/proxy-url" = let
      proxyHostConfig = outputs.nixosConfigurations.fakesynology-nixos.config;
    in {
      content = "http://hilot:${config.sops.placeholder."services/hilot/proxy-password"}@${proxyHostConfig.networking.fqdn}:${toString (lib.head proxyHostConfig.services._3proxy.services).bindPort}";

      restartUnits = ["hilot-downloader.service"];
    };
  };

  services = {
    postgresql = {
      authRules = ["local hilot hilot peer"];

      ensureDatabases = ["hilot"];

      ensureUsers = [
        {
          name = "hilot";

          ensureDBOwnership = true;
        }
      ];
    };

    nats.settings.authorization.token = config.sops.placeholder."services/nats/tokens/hilot/hashed-token";

    # gatus checks those, so only `/healthz` goes public; prometheus scrapes `/metrics` over the tailnet
    traefik.dynamicConfigOptions.http = {
      routers =
        lib.mapAttrs (name: _: {
          entryPoints = ["https"];
          rule = "Host(`${name}.${config.networking.fqdn}`) && Path(`/healthz`)";

          service = name;
        })
        httpPorts;

      services = lib.mapAttrs (_: port: {loadBalancer.servers = [{url = "http://127.0.0.1:${toString port}";}];}) httpPorts;
    };
  };

  # `sudo hilot-cookies <cookies.txt>`: the import needs the database role and the cookie keys of the downloader
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "hilot-cookies";

      runtimeInputs = [config.systemd.package];

      excludeShellChecks = (import ../../../../../shared.nix).ignoredShellcheckRules;

      text = ''
        cookies=$(realpath $1)

        # the dynamic user can't read the file where it is; pass it as a credential
        systemd-run \
          --pipe \
          --wait \
          --collect \
          --quiet \
          --property=DynamicUser=yes \
          --property=User=${config.systemd.services.hilot-downloader.serviceConfig.User} \
          --property=LoadCredential=COOKIES__KEYS:${config.sops.secrets."services/hilot/cookie-keys".path} \
          --property=LoadCredential=cookies.txt:$cookies \
          --setenv=SECRETSPEC_PROVIDER=${config.systemd.services.hilot-downloader.environment.SECRETSPEC_PROVIDER} \
          --setenv=XDG_CONFIG_HOME=${config.systemd.services.hilot-downloader.environment.XDG_CONFIG_HOME} \
          ${lib.getExe' pkgs.hilot "hilot-cookies"} "\''${CREDENTIALS_DIRECTORY}/cookies.txt" # systemd expands it inside the unit
      '';
    })
  ];

  systemd.services = let
    settingsFormat = pkgs.formats.toml {};

    mkHttp = port: {
      host = "0.0.0.0";
      inherit port;
    };

    settings = {
      database.url = "postgresql+asyncpg:///hilot?host=/run/${config.systemd.services.postgresql.serviceConfig.RuntimeDirectory}";

      nats.servers = ["nats://${config.services.nats.settings.host}:${toString config.services.nats.port}"];

      s3 = {
        endpoint_url = "http://${config.services.garage.settings.s3_api.api_bind_addr}";
        region = config.services.garage.settings.s3_api.s3_region;

        bucket = "hilot";

        # the bucket expires the files a day after their upload, see `garage-setup`
        reuse_period = "12:00:00";
      };

      disk = {
        min_free_space = "2 GiB";
        postpone_delay = "0:01:00";
      };

      downloader = {
        concurrency = 2;

        http = mkHttp httpPorts.hilot-downloader;
      };

      transcoder = {
        concurrency = 1;

        http = mkHttp httpPorts.hilot-transcoder;
      };
    };

    # each bot needs its own `hilot.toml` for its port
    mkConfigHome = name: settings:
      pkgs.linkFarm "${name}-config" {
        "hilot.toml" = settingsFormat.generate "hilot.toml" settings;

        # turn off the secretspec's audit log: it goes into the home, which a dynamic user can't write to
        "secretspec/config.toml" = settingsFormat.generate "secretspec-config.toml" {audit.enabled = false;};
      };

    sharedConfigHome = mkConfigHome "hilot" settings;

    # shared by every hilot service: they exchange tasks through nats and files through garage
    shared = {
      wantedBy = ["multi-user.target"];

      requires = [
        # keep-sorted start
        "garage-setup.service"
        "nats.service"
        # keep-sorted end
      ];

      after = [
        # keep-sorted start
        "garage-setup.service"
        "nats.service"
        # keep-sorted end
      ];

      environment.SECRETSPEC_PROVIDER = "systemd-credential://";

      serviceConfig = {
        DynamicUser = true;
        PrivateTmp = true; # `DynamicUser` implies `disconnected`, a tmpfs of a tenth of the ram, which no download fits into; `true` keeps it on the disk

        LoadCredential = [
          "NATS__TOKEN:${config.sops.secrets."services/hilot/nats-token".path}"

          "S3__ACCESS_KEY_ID:${config.sops.secrets."services/hilot/s3-access-key-id".path}"
          "S3__SECRET_ACCESS_KEY:${config.sops.secrets."services/hilot/s3-secret-access-key".path}"
        ];

        KillMode = "mixed"; # the default `control-group` kills ffmpeg along with the service; `mixed` lets the service finish its running tasks first

        Restart = "always";
        RestartSec = 2;
      };
    };

    # shared by the services on the database: postgresql's peer auth takes the role from the user name
    database = {
      requires = ["hilot-migrate.service"];

      after = ["hilot-migrate.service"];

      serviceConfig.User = config.systemd.services.hilot-migrate.serviceConfig.User;
    };
  in
    lib.mkMerge [
      {
        hilot-migrate = {
          description = "hilot database migrations";

          requires = ["postgresql.target"];
          after = ["postgresql.target"];

          environment.XDG_CONFIG_HOME = sharedConfigHome;

          serviceConfig = {
            Type = "oneshot";

            RemainAfterExit = "yes";

            ExecStart = "${lib.getExe' pkgs.hilot "hilot-migrate"} upgrade head";

            DynamicUser = true;
            User = "hilot";
          };
        };
      }

      (lib.mapAttrs' (name: port:
          lib.nameValuePair "hilot-bot-${name}" (lib.mkMerge [
            shared

            database

            {
              description = "hilot Telegram client of ${name}";

              environment.XDG_CONFIG_HOME = mkConfigHome "hilot-bot-${name}" (settings
                // {
                  inherit (lib.importTOML "${inputs.hilot}/hilot.toml") telegram; # the same app and device as `hilot-login`, which creates the session string from the repository

                  bot = {
                    concurrency = 2;

                    max_message_age = "0:30:00";

                    http = mkHttp port;
                  };
                });

              serviceConfig = {
                ExecStart = lib.getExe' pkgs.hilot "hilot-bot";

                LoadCredential = ["SESSION_STRING:${config.sops.secrets."services/hilot/accounts/${name}/session-string".path}"];
              };
            }
          ]))
        botPorts)

      {
        hilot-downloader = lib.mkMerge [
          shared

          database

          {
            description = "hilot media downloader";

            environment = {
              XDG_CONFIG_HOME = sharedConfigHome;

              XDG_CACHE_HOME = "%C/hilot-downloader"; # yt-dlp and deno write their caches to `~/.cache` by default, which a dynamic user can't write to
            };

            serviceConfig = {
              ExecStart = lib.getExe' pkgs.hilot "hilot-downloader";

              CacheDirectory = "hilot-downloader";

              LoadCredential = [
                "COOKIES__KEYS:${config.sops.secrets."services/hilot/cookie-keys".path}"

                "DOWNLOADER__PROXY:${config.sops.templates."services/hilot/proxy-url".path}"
              ];
            };
          }
        ];

        hilot-transcoder = lib.mkMerge [
          shared

          {
            description = "hilot media transcoder";

            environment.XDG_CONFIG_HOME = sharedConfigHome;

            serviceConfig.ExecStart = lib.getExe' pkgs.hilot "hilot-transcoder";
          }
        ];

        garage-setup.script = lib.mkAfter ''
          access_key_id=$(<${config.sops.secrets."services/hilot/s3-access-key-id".path})
          secret_access_key=$(<${config.sops.secrets."services/hilot/s3-secret-access-key".path})

          garage bucket info hilot >/dev/null 2>&1 || garage bucket create hilot
          garage key info $access_key_id >/dev/null 2>&1 || garage key import --yes -n hilot $access_key_id $secret_access_key
          garage bucket allow --read --write --owner hilot --key $access_key_id

          # the bot leaves the sent files for the other accounts to send, so the bucket expires every object, also the leftovers of a killed service, a day after its upload
          ${lib.getExe pkgs.curl} --fail-with-body --silent --show-error \
            --config - <<<"user = $access_key_id:$secret_access_key" \
            --aws-sigv4 aws:amz:${config.services.garage.settings.s3_api.s3_region}:s3 \
            --upload-file ${pkgs.writeText "hilot-lifecycle.xml" "<LifecycleConfiguration><Rule><ID>expire-objects</ID><Status>Enabled</Status><Filter></Filter><Expiration><Days>1</Days></Expiration></Rule></LifecycleConfiguration>"} \
            "http://${config.services.garage.settings.s3_api.api_bind_addr}/hilot?lifecycle"
        '';
      }
    ];
}
