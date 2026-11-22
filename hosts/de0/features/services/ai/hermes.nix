{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets = lib.mkMerge (lib.mapAttrsToList (name: _machine: let
        agentSecret.restartUnits = ["hermes-${name}.service"];
      in {
        "services/hermes/agents/${name}/telegram/bot-token" = agentSecret;

        "services/hermes/agents/${name}/telegram/chat" = agentSecret; # a dm's id is the id of the person the agent talks to
        "services/hermes/agents/${name}/telegram/allowed-users" = agentSecret;

        "services/hermes/agents/${name}/ssh/private-key" = agentSecret;

        "services/cliproxyapi/users/hermes-${name}/inference-key" = agentSecret;

        "services/hermes/agents/${name}/mcpproxy/api-key" = agentSecret;
      })
      config.virtualisation.agentbox.machines);

    templates =
      lib.mapAttrs' (name: _machine:
        lib.nameValuePair "services/hermes/agents/${name}.env" {
          content = ''
            TELEGRAM_BOT_TOKEN=${config.sops.placeholder."services/hermes/agents/${name}/telegram/bot-token"}

            TELEGRAM_GROUP_ALLOWED_CHATS=${config.sops.placeholder."services/hermes/agents/${name}/telegram/chat"}
            TELEGRAM_ALLOWED_USERS=${config.sops.placeholder."services/hermes/agents/${name}/telegram/allowed-users"}

            TELEGRAM_HOME_CHANNEL=${config.sops.placeholder."services/hermes/agents/${name}/telegram/chat"}

            CLIPROXYAPI_API_KEY=${config.sops.placeholder."services/cliproxyapi/users/hermes-${name}/inference-key"}

            MCPPROXY_API_KEY=${config.sops.placeholder."services/hermes/agents/${name}/mcpproxy/api-key"}
          '';
        })
      config.virtualisation.agentbox.machines;
  };

  programs.ssh.knownHosts =
    lib.mapAttrs' (name: machine:
      lib.nameValuePair "agentbox-${name}" {
        hostNames = [machine.address];

        publicKey = machine.sshHostKey;
      })
    config.virtualisation.agentbox.machines;

  # ssh looks its own user up, and a dynamic one resolves only through nscd, which openresolv restarts on every dns change
  users = lib.mkMerge (lib.mapAttrsToList (name: _machine: {
      users."hermes-${name}" = {
        isSystemUser = true;

        group = config.users.groups."hermes-${name}".name;

        home = "/var/lib/${config.systemd.services."hermes-${name}".serviceConfig.StateDirectory}"; # hermes keeps state under `~` too, such as its gateway locks in `~/.local/state`
      };

      groups."hermes-${name}" = {};
    })
    config.virtualisation.agentbox.machines);

  # every agentbox's agent is a hermes gateway here and runs its commands in its agentbox
  systemd.services = let
    package = pkgs.hermes-agent.override {
      defaultDependencyGroups = [
        # keep-sorted start
        "mcp" # for each agentbox's mcp proxy
        "messaging"
        # keep-sorted end
      ];
    };
  in
    lib.mapAttrs' (name: machine:
      lib.nameValuePair "hermes-${name}" rec {
        description = "Hermes gateway of the ${name} agentbox";

        wantedBy = ["multi-user.target"];

        after = ["network-online.target"];
        wants = ["network-online.target"];

        reloadIfChanged = true; # a deploy waits for the running turns to finish instead of cutting them off

        path = with pkgs; [
          # keep-sorted start
          gnutar # the terminal uploads files to the agentbox as a local `tar` piped into ssh
          openssh # the terminal runs every command over ssh
          # keep-sorted end
        ];

        environment.HERMES_HOME = "%S/${serviceConfig.StateDirectory}";

        # hermes writes `config.yaml` itself, so the settings here are merged into it instead of replacing it
        preStart = let
          cliproxyapi = {
            base_url = "http://127.0.0.1:${toString config.services.cliproxyapi.settings.server.port}/v1";

            key_env = "CLIPROXYAPI_API_KEY";
          };

          settings = {
            # cliproxyapi serves every model; `/model` and `/reasoning` switch the model and its effort for the chat's session
            model =
              cliproxyapi
              // {
                provider = "custom";

                default = "antigravity/claude-sonnet-4-6";
              };

            # hermes draws through openrouter's chat protocol, which cliproxyapi speaks too; antigravity's quota, unlike codex's, isn't needed for anything else
            providers.openrouter = cliproxyapi;
            image_gen = {
              provider = "openrouter";

              openrouter.model = "antigravity/gemini-3.1-flash-image";
            };

            # the gateway reads its terminal settings only from `config.yaml` and `.env` in `HERMES_HOME`, never from its own environment
            terminal = {
              backend = "ssh";

              ssh_host = machine.address;

              ssh_user = "agent";

              ssh_key = "/run/credentials/hermes-${name}.service/ssh-key";
            };

            # every mcp server runs in the agentbox, behind its mcpproxy, which the agent manages itself
            mcp_servers.mcpproxy = {
              url = "http://${machine.address}:${toString config.virtualisation.agentbox.mcpProxy.port}/mcp";

              headers.X-API-Key = "\${MCPPROXY_API_KEY}"; # hermes fills it in from its environment when it connects
            };

            agent = {
              disabled_toolsets = [
                # keep-sorted start
                "browser" # the agentbox's playwright behind its mcpproxy drives the browser instead
                "computer_use" # would drive the desktop of de0, not of the agentbox
                "connections" # installs catalog mcp servers as processes on de0 without asking in telegram, instead of behind the agentbox's mcpproxy
                # keep-sorted end
              ];

              # hermes reads context files such as `AGENTS.md` only from its own host, so the agent learns about its agentbox's repo from here
              environment_hint = ''
                Your terminal is `agentbox-${name}`, a persistent NixOS container that belongs to you. Its system, services and your home are declared in your own repository `~/projects/agentbox-${name}` there, which you commit, push and deploy yourself. It starts as an empty `git init` with the remotes `origin` and `upstream` and nothing checked out, where `git pull` has no branch to track; run `git fetch origin` and `git switch main` there once. Then read its `AGENTS.md` before changing the system, installing software or publishing a service.

                Install software by declaring it in that repository and deploying it, never with `nix profile`, `nix-env`, `pip install` or other imperative installs.

                Your browser is shared with the people you work for, who see and control it at https://browser.${name}.${config.virtualisation.agentbox.domain}. Drive it with the `playwright` tools behind your mcpproxy: find them with its `retrieve_tools` and run them through its `call_tool_read` and `call_tool_write`. When a site wants a login, a captcha or a confirmation only a person can give, send them that link and wait until they say they are done.

                yt-dlp and gallery-dl already go out through a home proxy, since YouTube asks de0's address to sign in, and already use the shared logins of the cookie browser at home, which reach `~/.local/share/cookies.txt` every five minutes. When a site still wants an account, ask the people you work for to log in to it there; for a login only your own browser has, pass `--cookies-from-browser chromium+basictext:~/.local/share/chromium/Default` to yt-dlp.

                Draw and edit pictures with `image_generate`, which calls an image model, rather than with code. A `MEDIA:` path in your reply may point into your agentbox: the gateway copies a file of up to 50 MB from there to the chat.
              '';
            };

            group_sessions_per_user = false; # everyone in the chat shares one session

            streaming.enabled = true; # stream replies as they're written; a group gets edits of one message, a dm telegram's native drafts

            telegram.gateway_restart_notification = false; # every deploy restarts the gateway; drop its "shutting down" and "gateway online" messages from the chat

            display.platforms.telegram = {
              tool_progress = "verbose"; # telegram hides tool calls by default; show each one as it runs, with a terminal command whole, while "all" cuts it to one line

              tool_preview_length = 500; # caps only the arguments of the other tools, such as a whole file being written
            };
          };
        in "${import "${inputs.hermes-agent}/nix/configMergeScript.nix" {inherit pkgs;}} ${pkgs.writeText "hermes-${name}-settings.json" (builtins.toJSON settings)} $HERMES_HOME/config.yaml";

        serviceConfig = {
          User = config.users.users."hermes-${name}".name;

          StateDirectory = "hermes/${name}";

          LoadCredential = ["ssh-key:${config.sops.secrets."services/hermes/agents/${name}/ssh/private-key".path}"]; # the sandbox hides `/run/secrets`

          EnvironmentFile = config.sops.templates."services/hermes/agents/${name}.env".path;

          # hermes reads host files outside its tools, such as any `MEDIA:` path a reply names, which it sends to the chat; the agent's files live in its agentbox, so the gateway sees only the world-readable `/nix/store` and `/etc` and its own state
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          TemporaryFileSystem = [
            # keep-sorted start
            "/efi:ro"
            "/media:ro"
            "/mnt:ro"
            "/nix/var:ro"
            "/opt:ro"
            "/run:ro"
            "/srv:ro"
            "/var:ro"
            # keep-sorted end
          ];
          PrivateDevices = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";

          ExecStart = "${lib.getExe' package "hermes"} gateway run";
          ExecReload = "${lib.getExe' pkgs.coreutils "kill"} -USR1 $MAINPID"; # hermes restarts itself once no turn is running; sigterm interrupts them
          ExecStop = "-${package.hermesVenv}/bin/python3 -m gateway.systemd_stop_mark"; # without the mark hermes takes systemd's sigterm for an unexpected kill and exits 1

          Restart = "on-failure";
          RestartSec = 10;

          # hermes exits 75 to be started again after it drains itself, and 78 on a fatal config error such as a bot token another gateway holds, which a restart won't fix
          SuccessExitStatus = 75;
          RestartForceExitStatus = 75;
          RestartPreventExitStatus = 78;
        };
      })
    config.virtualisation.agentbox.machines;
}
