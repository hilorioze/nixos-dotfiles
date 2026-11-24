{
  # keep-sorted start
  config,
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: let
  novncPort = 6080;

  exportPort = 6090;
in {
  sops = let
    consumers = map (name: "agentbox-${name}") (lib.attrNames outputs.nixosConfigurations.de0.config.virtualisation.agentbox.machines) ++ ["hilot"];
  in {
    secrets = lib.genAttrs (map (consumer: "services/cookie-browser/users/${consumer}/hashed-password") consumers) (_: {});

    templates."services/traefik/cookie-browser.htpasswd" = {
      content = lib.concatMapStringsSep "\n" (consumer: "${consumer}:${config.sops.placeholder."services/cookie-browser/users/${consumer}/hashed-password"}") consumers;

      owner = config.users.users.traefik.name;

      restartUnits = ["traefik.service"]; # traefik reads the file only when it loads the middleware
    };
  };

  users = {
    users.cookie-browser = {
      isSystemUser = true;

      group = config.users.groups.cookie-browser.name;

      home = "/var/lib/cookie-browser";
      createHome = true;

      linger = true; # keeps its systemd manager running, which starts the browser's session without a login
    };

    groups.cookie-browser = {};
  };

  # a chrome at home, whose logins every consumer takes as cookies; novnc shows it
  home-manager.users.cookie-browser = {
    config,
    osConfig,
    ...
  }: {
    home.stateVersion = osConfig.system.stateVersion;

    wayland.windowManager.labwc = {
      enable = true;

      xwayland.enable = false; # chrome runs on wayland itself
    };

    # shows labwc's output to novnc
    services.wayvnc = {
      enable = true;

      autoStart = true;

      settings = {
        address = "127.0.0.1";

        port = 5900;
      };
    };

    systemd.user = {
      # stop the session's services together with labwc, whose autostart starts them
      targets.labwc-session.Unit = {
        BindsTo = ["labwc.service"];
        After = ["labwc.service"];
      };

      services = {
        # home-manager leaves starting labwc to a display manager, which a server has none of
        labwc = {
          Install.WantedBy = ["default.target"];

          Service = {
            Environment = ["WLR_BACKENDS=headless"]; # no screen or input devices; the remote viewer brings both

            ExecStart = lib.getExe config.wayland.windowManager.labwc.package;

            Restart = "always"; # its menu's exit ends it cleanly, and nothing else would bring the desktop back
          };
        };

        google-chrome = {
          Unit = {
            After = [config.wayland.systemd.target];
            PartOf = [config.wayland.systemd.target];
          };

          Install.WantedBy = [config.wayland.systemd.target];

          Service = {
            ExecStart = lib.escapeShellArgs [
              (lib.getExe pkgs.google-chrome) # sites see its own brand, where a plain chromium is rare enough to stand out
              "--ozone-platform=wayland" # labwc runs without xwayland
              "--start-maximized"
              "--ignore-gpu-blocklist" # the vm has no gpu, and chrome keeps webgl off on mesa's software renderer; a browser without webgl looks like a bot
            ];

            Restart = "always"; # closing its last window ends it cleanly, and the logins need it running
          };
        };
      };
    };
  };

  # a desktop's usual fonts; a browser that finds a single font looks like a bot
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      # keep-sorted start
      noto-fonts
      noto-fonts-cjk-sans
      # keep-sorted end
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    middlewares.cookies-basic-auth.basicAuth.usersFile = config.sops.templates."services/traefik/cookie-browser.htpasswd".path;

    routers = {
      cookie-browser-http = {
        entryPoints = ["http"];
        rule = "Host(`cookie-browser.${config.networking.fqdn}`)";

        middlewares = ["redirect-to-https"];

        service = "noop@internal";
      };

      cookie-browser = {
        entryPoints = ["https"];
        rule = "Host(`cookie-browser.${config.networking.fqdn}`)";

        # authentik first, so not even the redirect answers without a session
        middlewares = [
          "oidc-login"
          "novnc-viewer"
        ];

        service = "cookie-browser";
      };

      # de0's gatus checks that the viewer is served, without an authentik session
      cookie-browser-health = {
        entryPoints = ["https"];
        rule = "Host(`cookie-browser.${config.networking.fqdn}`) && Path(`/health`)";

        middlewares = [
          # keep-sorted start
          "no-upgrade"
          "novnc-health"
          # keep-sorted end
        ];

        service = "cookie-browser";
      };

      cookies = {
        entryPoints = ["https"];
        rule = "Host(`cookies.${config.networking.fqdn}`)";

        middlewares = ["cookies-basic-auth"];

        service = "cookies";
      };

      # de0's gatus checks that the profile's cookies can be read, without getting them
      cookies-health = {
        entryPoints = ["https"];
        rule = "Host(`cookies.${config.networking.fqdn}`) && Path(`/health`)";

        service = "cookies";
      };
    };

    services = {
      cookie-browser.loadBalancer.servers = [{url = "http://127.0.0.1:${toString novncPort}";}];

      cookies.loadBalancer.servers = [{url = "http://127.0.0.1:${toString exportPort}";}];
    };
  };

  systemd.services = {
    # serves the novnc viewer and passes its websocket on to wayvnc
    cookie-browser-novnc = {
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        DynamicUser = true;

        ExecStart = let
          inherit (config.home-manager.users.cookie-browser.services.wayvnc) settings;
        in
          lib.escapeShellArgs [
            (lib.getExe pkgs.python3Packages.websockify)
            "--web=${pkgs.novnc}/share/webapps/novnc"
            "--file-only"
            "127.0.0.1:${toString novncPort}"
            "${settings.address}:${toString settings.port}"
          ];

        Restart = "on-failure";
      };
    };

    cookie-browser-export = {
      wantedBy = ["multi-user.target"];

      environment = {
        PROFILE_PATH = "${config.home-manager.users.cookie-browser.xdg.configHome}/google-chrome/Default";

        PORT = toString exportPort;
      };

      serviceConfig = {
        User = config.users.users.cookie-browser.name;

        ExecStart = pkgs.writers.writePython3 "cookie-export" {
          libraries = with pkgs.python3Packages; [
            # keep-sorted start
            aiohttp
            yt-dlp
            # keep-sorted end
          ];

          doCheck = false; # treefmt lints the script with ruff
        } (builtins.readFile ./cookie-export.py);

        Restart = "on-failure";
      };
    };
  };
}
