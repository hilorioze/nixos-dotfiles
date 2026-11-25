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
      hilot-detector = 9105;
      hilot-downloader = 9102;
      hilot-transcoder = 9103;
      # keep-sorted end
    };

  proxyPort = 3128; # haproxy's port in front of the home proxies

  browserProxyPort = 3129; # 3proxy's port in front of haproxy's, which signs in for chrome

  browserPort = 9222; # the devtools port of `hilot-browser`

  novncPort = 6080;

  wayvncConfig = pkgs.writeText "wayvnc-config" ''
    address=127.0.0.1
    port=5900
  '';

  # the proxies and cookie browsers at home, cex-nixos first as the steadier one
  homeHosts = with outputs.nixosConfigurations; [
    cex-nixos
    fakesynology-nixos
  ];
in {
  sops = {
    secrets = let
      # garage-setup imports the key; the services require it and restart with it
      s3Secret.restartUnits = ["garage-setup.service"];
    in
      lib.mkMerge [
        {
          # printf '["%s"]\n' $(, openssl rand -base64 32 | tr '+/' '-_')
          "services/hilot/encryption-keys".restartUnits = [
            # keep-sorted start
            "hilot-detector.service"
            "hilot-downloader.service"
            # keep-sorted end
          ];

          # token=$(, openssl rand -hex 32); printf 'token: %s\nhashed-token: %s\n' $token $(, mkpasswd --method=bcrypt --rounds=10 $token)
          "services/hilot/nats-token".restartUnits = lib.mkMerge [
            [
              # keep-sorted start
              "hilot-detector.service"
              "hilot-downloader.service"
              "hilot-transcoder.service"
              # keep-sorted end
            ]

            (lib.mapAttrsToList (name: _: "hilot-bot-${name}.service") botPorts)
          ];

          # , mkpasswd --method=bcrypt --rounds=10
          "services/nats/tokens/hilot/hashed-token" = {};

          # password=$(, openssl rand -hex 32); printf 'password: %s\nhashed-password: %s\n' $password $(, openssl passwd -1 $password)
          "services/hilot/proxy-password".restartUnits = ["3proxy.service"];

          # password=$(, openssl rand -hex 32); printf 'password: %s\nhashed-password: %s\n' $password $(, htpasswd -inBC 10 "" <<<$password | cut --delimiter=: --fields=2)
          "services/hilot/cookie-browser-password" = {};

          # printf 'access-key-id: GK%s\nsecret-access-key: %s\n' $(, openssl rand -hex 12) $(, openssl rand -hex 32)
          "services/hilot/s3-access-key-id" = s3Secret;
          "services/hilot/s3-secret-access-key" = s3Secret;
        }

        # to generate a session-string, in the hilot repository execute `hilot-login`
        (lib.mapAttrs' (name: _: lib.nameValuePair "services/hilot/accounts/${name}/session-string" {restartUnits = ["hilot-bot-${name}.service"];}) botPorts)
      ];

    templates = {
      "services/hilot/proxy-url" = {
        content = "http://hilot:${config.sops.placeholder."services/hilot/proxy-password"}@127.0.0.1:${toString proxyPort}";

        restartUnits = ["hilot-downloader.service"];
      };

      "services/cookie-browser/curlrc".content = "user = \"hilot:${config.sops.placeholder."services/hilot/cookie-browser-password"}\"";
    };
  };

  # a desktop's usual fonts for `hilot-browser`; a browser that finds a single font looks like a bot
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      # keep-sorted start
      noto-fonts
      noto-fonts-cjk-sans
      # keep-sorted end
    ];
  };

  # mesa's software renderer, for the webgl of `hilot-browser`
  hardware.graphics.enable = true;

  # postgresql's peer auth looks the connecting user up by id; a dynamic one resolves only through nscd, which openresolv restarts on every dns change
  users = {
    users.hilot = {
      isSystemUser = true;

      group = config.users.groups.hilot.name;
    };

    groups.hilot = {};
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

    # hilot takes a single proxy; fail over between the home proxies behind one local port, in the order of `homeHosts`
    haproxy = {
      enable = true;

      config = let
        mkServer = index: host: "server ${host.config.networking.hostName} ${host.config.networking.fqdn}:${toString host.config.services._3proxy.namedServices.hilot.bindPort}${lib.optionalString (index > 1) " backup"}";
      in ''
        resolvers system
          parse-resolv-conf

        listen hilot-proxy
          mode tcp
          bind 127.0.0.1:${toString proxyPort}

          timeout connect 5s
          timeout client 1h
          timeout server 1h

          default-server check resolvers system init-addr last,libc,none
          ${lib.concatImapStringsSep "\n  " mkServer homeHosts}
      '';
    };

    # chrome takes a proxy without its credentials, so this one passes its connections on to haproxy's with them
    _3proxy = {
      enable = true;

      namedServices.hilot-browser = {
        type = "proxy";

        bindAddress = "127.0.0.1";
        bindPort = browserProxyPort;

        auth = ["iponly"]; # with `none` 3proxy skips every acl, including the `allow` that `parent` belongs to

        acl = [{rule = "allow";}];

        extraConfig = ''parent 1000 connect 127.0.0.1 ${toString proxyPort} hilot $"/run/credentials/3proxy.service/proxy-password"'';
      };
    };

    nats.settings.authorization.token = config.sops.placeholder."services/nats/tokens/hilot/hashed-token";

    traefik.dynamicConfigOptions.http = {
      routers = lib.mkMerge [
        # gatus checks those, so only `/healthz` goes public; prometheus scrapes `/metrics` over the tailnet
        (lib.mapAttrs (name: _: {
            entryPoints = ["https"];
            rule = "Host(`${name}.${config.networking.fqdn}`) && Path(`/healthz`)";

            service = name;
          })
          httpPorts)

        # novnc shows the browser, where the synthid.com accounts of `hilot-detector` are signed in
        {
          hilot-browser-http = {
            entryPoints = ["http"];
            rule = "Host(`hilot-browser.${config.networking.fqdn}`)";

            middlewares = ["redirect-to-https"];

            service = "noop@internal";
          };

          hilot-browser = {
            entryPoints = ["https"];
            rule = "Host(`hilot-browser.${config.networking.fqdn}`)";

            # authentik first, so not even the redirect answers without a session
            middlewares = [
              "oidc-login"
              "novnc-viewer"
            ];

            service = "hilot-browser";
          };

          # de0's gatus checks that the viewer is served, without an authentik session
          hilot-browser-health = {
            entryPoints = ["https"];
            rule = "Host(`hilot-browser.${config.networking.fqdn}`) && Path(`/health`)";

            middlewares = [
              # keep-sorted start
              "no-upgrade"
              "novnc-health"
              # keep-sorted end
            ];

            service = "hilot-browser";
          };
        }
      ];

      services = lib.mkMerge [
        (lib.mapAttrs (_: port: {loadBalancer.servers = [{url = "http://127.0.0.1:${toString port}";}];}) httpPorts)

        {hilot-browser.loadBalancer.servers = [{url = "http://127.0.0.1:${toString novncPort}";}];}
      ];
    };
  };

  systemd = {
    timers.hilot-cookies-sync = {
      wantedBy = ["timers.target"];

      timerConfig = {
        OnActiveSec = 0;
        OnUnitActiveSec = "5min"; # google rotates its session cookies while the cookie browser has its pages open
      };
    };

    services = let
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

        detector = {
          concurrency = 2;

          http = mkHttp httpPorts.hilot-detector;

          browser_url = "http://127.0.0.1:${toString browserPort}";
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

      # shared by every hilot program: it reads its secrets as credentials of a dynamic user
      credentials = {
        environment.SECRETSPEC_PROVIDER = "systemd-credential://";

        serviceConfig.DynamicUser = true;
      };

      # shared by every hilot service: they exchange tasks through nats and files through garage
      shared = {
        wantedBy = ["multi-user.target"];

        after = [
          # keep-sorted start
          "garage-setup.service"
          "nats.service"
          # keep-sorted end
        ];
        requires = [
          # keep-sorted start
          "garage-setup.service"
          "nats.service"
          # keep-sorted end
        ];

        serviceConfig = {
          PrivateTmp = true; # `DynamicUser` implies `disconnected`, a tmpfs of a tenth of the ram, which no download fits into; `true` keeps it on the disk

          LoadCredential = [
            "NATS__TOKEN:${config.sops.secrets."services/hilot/nats-token".path}"

            "S3__ACCESS_KEY_ID:${config.sops.secrets."services/hilot/s3-access-key-id".path}"
            "S3__SECRET_ACCESS_KEY:${config.sops.secrets."services/hilot/s3-secret-access-key".path}"
          ];

          KillMode = "mixed"; # the default `control-group` kills `ffmpeg` along with the service; `mixed` lets the service finish its running tasks first

          Restart = "always";
          RestartSec = 2;
        };
      };

      # shared by the services on the database: postgresql's peer auth takes the role from the user name
      database = {
        after = ["hilot-migrate.service"];
        requires = ["hilot-migrate.service"];

        serviceConfig.User = config.systemd.services.hilot-migrate.serviceConfig.User;
      };
    in
      lib.mkMerge [
        {
          hilot-migrate = {
            after = ["postgresql.target"];
            requires = ["postgresql.target"];

            environment.XDG_CONFIG_HOME = sharedConfigHome;

            serviceConfig = {
              Type = "oneshot";

              RemainAfterExit = "yes";

              DynamicUser = true;
              User = config.users.users.hilot.name; # systemd takes the static user of the name instead of allocating one

              ExecStart = "${lib.getExe' pkgs.hilot "hilot-migrate"} upgrade head";
            };
          };
        }

        (lib.mapAttrs' (name: port:
            lib.nameValuePair "hilot-bot-${name}" (lib.mkMerge [
              credentials

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

                      # only the accounts that have started the bot check in
                      check_ins = [
                        {
                          bot = "sheeridvn_bot";
                          command = "/start";
                          buttons = [
                            "start_me"
                            "start_checkin"
                          ];

                          # the bot's day starts at an unknown midnight; the window misses both utc's and vietnam's
                          start = "09:00:00";
                          end = "16:00:00";
                        }
                      ];

                      http = mkHttp port;
                    };
                  });

                serviceConfig = {
                  LoadCredential = ["SESSION_STRING:${config.sops.secrets."services/hilot/accounts/${name}/session-string".path}"];

                  ExecStart = lib.getExe' pkgs.hilot "hilot-bot";
                };
              }
            ]))
          botPorts)

        {
          hilot-downloader = lib.mkMerge [
            credentials

            shared

            database

            {
              environment = {
                XDG_CONFIG_HOME = sharedConfigHome;

                XDG_CACHE_HOME = "%C/hilot-downloader"; # yt-dlp and deno write their caches to `~/.cache` by default, which a dynamic user can't write to
              };

              serviceConfig = {
                CacheDirectory = "hilot-downloader";

                LoadCredential = [
                  "ENCRYPTION__KEYS:${config.sops.secrets."services/hilot/encryption-keys".path}"

                  "DOWNLOADER__PROXY:${config.sops.templates."services/hilot/proxy-url".path}"
                ];

                ExecStart = lib.getExe' pkgs.hilot "hilot-downloader";
              };
            }
          ];

          hilot-transcoder = lib.mkMerge [
            credentials

            shared

            database

            {
              environment.XDG_CONFIG_HOME = sharedConfigHome;

              serviceConfig.ExecStart = lib.getExe' pkgs.hilot "hilot-transcoder";
            }
          ];

          # a chrome on a headless wayland output, whose synthid.com page attests the checks of `hilot-detector`, and where its accounts are signed in
          hilot-browser = {
            wantedBy = ["multi-user.target"];

            # the browser goes out from the home address, as a desktop would
            after = ["3proxy.service"];
            requires = ["3proxy.service"];

            environment = {
              WLR_BACKENDS = "headless";
              WLR_RENDERER = "pixman"; # the vm has no gpu

              XDG_RUNTIME_DIR = "%t/hilot-browser";

              TZ = "Europe/Dublin"; # the zone of the home proxy's address, which the page sees
            };

            serviceConfig = {
              DynamicUser = true;

              RuntimeDirectory = "hilot-browser";
              CacheDirectory = "hilot-browser";

              # labwc ends with the browser, so both restart together
              ExecStart = lib.escapeShellArgs [
                (lib.getExe pkgs.labwc)
                "--startup"
                "${lib.getExe pkgs.wayvnc} --config=${wayvncConfig}" # shows the output to novnc; without a config file of its own wayvnc won't start
                "--session"
                (lib.escapeShellArgs [
                  (lib.getExe pkgs.google-chrome) # a plain chromium is rare enough to stand out
                  "--ozone-platform=wayland" # labwc runs without xwayland
                  "--start-maximized"
                  "--ignore-gpu-blocklist" # chrome keeps webgl off on mesa's software renderer; a browser without webgl looks like a bot
                  "--proxy-server=http://127.0.0.1:${toString browserProxyPort}"
                  "--remote-debugging-port=${toString browserPort}"
                  "--user-data-dir=%C/hilot-browser"
                  "--no-first-run"
                  "--no-default-browser-check"
                ])
              ];

              Restart = "always";
              RestartSec = 2;
            };
          };

          # serves the novnc viewer and passes its websocket on to wayvnc
          hilot-browser-novnc = {
            wantedBy = ["multi-user.target"];

            serviceConfig = {
              DynamicUser = true;

              ExecStart = lib.escapeShellArgs [
                (lib.getExe pkgs.python3Packages.websockify)
                "--web=${pkgs.novnc}/share/webapps/novnc"
                "--file-only"
                "127.0.0.1:${toString novncPort}"
                "127.0.0.1:5900" # wayvnc's port in `wayvncConfig`
              ];

              Restart = "on-failure";
            };
          };

          hilot-detector = lib.mkMerge [
            credentials

            shared

            database

            {
              # the detector stays connected to the browser: stop it with the browser and start it again once the browser is back
              after = ["hilot-browser.service"];
              bindsTo = ["hilot-browser.service"];
              upheldBy = ["hilot-browser.service"];

              environment.XDG_CONFIG_HOME = sharedConfigHome;

              serviceConfig = {
                LoadCredential = ["ENCRYPTION__KEYS:${config.sops.secrets."services/hilot/encryption-keys".path}"];

                ExecStart = lib.getExe' pkgs.hilot "hilot-detector";
              };
            }
          ];

          # take the logins of the cookie browsers at home
          hilot-cookies-sync = lib.mkMerge [
            credentials

            database

            {
              environment.XDG_CONFIG_HOME = sharedConfigHome;

              serviceConfig = {
                Type = "oneshot";

                RuntimeDirectory = "hilot-cookies-sync";

                LoadCredential = [
                  "ENCRYPTION__KEYS:${config.sops.secrets."services/hilot/encryption-keys".path}"

                  "curlrc:${config.sops.templates."services/cookie-browser/curlrc".path}"
                ];

                ExecStart = [
                  "${lib.getExe pkgs.cookie-browser-fetch} %t/hilot-cookies-sync/cookies.txt %d/curlrc ${lib.concatMapStringsSep " " (host: host.config.networking.fqdn) homeHosts}"
                  "${lib.getExe' pkgs.hilot "hilot-cookies"} %t/hilot-cookies-sync/cookies.txt"
                ];
              };
            }
          ];

          "3proxy".serviceConfig.LoadCredential = ["proxy-password:${config.sops.secrets."services/hilot/proxy-password".path}"]; # the dynamic user can't read the file where sops puts it

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
  };
}
