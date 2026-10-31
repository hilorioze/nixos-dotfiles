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
  # claude runs a daemon per config dir, and a background session gets that daemon's env; give gateway sessions a config dir of their own
  gatewayConfigDir = "${config.programs.claude-code.configDir}-gateway";
in {
  sops.secrets = {
    "apps/cliproxyapi/inference-key" = {};

    "apps/syncthing/folders/claude/encryption-password" = {};
  };

  programs = {
    git.ignores = [".claude/worktrees/"]; # worktrees are nested repositories, which `git add --all` would stage as gitlinks

    claude-code = {
      enable = true;

      package = pkgs.symlinkJoin {
        name = "claude-code";

        inherit (pkgs.claude-code-with-node) version;

        paths = [pkgs.claude-code-with-node]; # the wakatime plugin hooks need node

        nativeBuildInputs = [pkgs.makeWrapper];

        # `CLAUDE_CODE_GATEWAY=1` runs claude through the gateway, which adds the models of every cliproxyapi account to `/model`
        postBuild = ''
          wrapProgram $out/bin/${pkgs.claude-code-with-node.meta.mainProgram} \
            --run ${lib.escapeShellArg ''
            picker=()

            if [[ -n ''${CLAUDE_CODE_GATEWAY-} ]]; then
              export ANTHROPIC_BASE_URL=https://claude-code-gateway.${outputs.nixosConfigurations.de0.config.networking.fqdn} ANTHROPIC_AUTH_TOKEN=$(<${config.sops.secrets."apps/cliproxyapi/inference-key".path})

              export CLAUDE_CONFIG_DIR=${gatewayConfigDir}

              export CLAUDE_CODE_GATEWAY_HINT_HEADERS=1 # let the gateway distinguish the main conversation from background requests

              export CLAUDE_CODE_PROMPT_CACHE_TTL=1h # without a claude.ai login, claude defaults to 5m
              export ENABLE_TOOL_SEARCH=true # behind a base url other than anthropic's, claude assumes tool search is unsupported: it waits for every mcp server before the first turn and keeps tool search off in a conversation that has run without it

              # claude reads the picker once, at launch; its quotas are laid out for this terminal
              if [[ -t 0 ]]; then
                read -r _ columns < <(${lib.getExe' pkgs.coreutils "stty"} size)

                # the key stays out of the process list
                if settings=$(${lib.getExe pkgs.curl} --fail --silent --max-time 3 --header @- "$ANTHROPIC_BASE_URL/model-picker?width=$columns" <<<"Authorization: Bearer $ANTHROPIC_AUTH_TOKEN"); then
                  picker=(--settings "$settings")
                fi
              fi
            else
              unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN CLAUDE_CONFIG_DIR CLAUDE_CODE_GATEWAY_HINT_HEADERS CLAUDE_CODE_PROMPT_CACHE_TTL ENABLE_TOOL_SEARCH # a claude started from a gateway session with `CLAUDE_CODE_GATEWAY=` still inherits them
            fi
          ''} \
            --add-flags '"''${picker[@]}"'
        '';

        inherit (pkgs.claude-code-with-node) meta;
      };

      enableMcpIntegration = true;

      plugins = [
        # keep-sorted start by_regex=inputs\.([\w-]+)
        inputs.claude-code-wakatime
        "${inputs.claude-plugins-official}/plugins/frontend-design"
        # keep-sorted end
      ];

      lspServers = {
        # keep-sorted start block=yes newline_separated=yes
        nil = {
          command = lib.getExe pkgs.nil;

          extensionToLanguage.".nix" = "nix";
        };

        pyright = {
          command = lib.getExe' pkgs.pyright "pyright-langserver";
          args = ["--stdio"];

          extensionToLanguage = {
            # keep-sorted start
            ".py" = "python";
            ".pyi" = "python";
            # keep-sorted end
          };
        };
        # keep-sorted end
      };

      settings = {
        autoCompactWindow = 220000; # actually triggers at 187k (reserves 20k output + 13k buffer)
        idleCompaction = false; # disable the extra summary request before an idle chat's prompt cache expires

        autoMemoryDirectory = "${config.services.syncthing.settings.folders.claude.path}/memory"; # global memory; shared between hosts

        worktree.bgIsolation = "none"; # let background sessions edit the main checkout

        attribution = false; # requires claude 2.1.281+; older versions skip the whole settings file

        awaySummaryEnabled = false; # disable the "※ recap" block generated after being away
        promptSuggestionEnabled = false; # disable the guess of the next message, a model request over the whole conversation after every reply

        preferredNotifChannel = "terminal_bell"; # `auto` ignores konsole; bell triggers a notification

        remoteControlAtStartup = true; # keep every session reachable from the phone
        inputNeededNotifEnabled = true; # ping the phone on prompt (permission or question)

        switchModelsOnFlag = true; # switch to the fallback model without asking when the safeguards flag a session

        feedbackDrafts = "off"; # disable the "✻ Bug report drafted" card and the `SendFeedback` tool

        statusLine = {
          type = "command";

          command = lib.getExe pkgs.claude-code-status-line;
        };

        # keep the computer awake and the displays on while claude works
        hooks = let
          # hooks run under `sh -c`, whose parent is the claude process; an inhibitor per process lets parallel sessions release only their own
          mkInhibitorHook = action: unitType: {
            type = "command";
            command = "${lib.getExe' pkgs.systemd "systemctl"} --user ${action} claude-inhibit@$PPID.${unitType}";
          };

          holdInhibitor = mkInhibitorHook "restart" "timer"; # the timer pulls the inhibitor in, restarting it only moves the lease end
          releaseInhibitor = mkInhibitorHook "stop" "service";
        in {
          # a turn starts with a prompt or, woken by a finished background task, with a tool call
          UserPromptSubmit = [{hooks = [holdInhibitor];}];
          PreToolUse = [{hooks = [holdInhibitor];}];

          # not `Stop`: an interrupted turn skips it; `idle_prompt` comes as soon as a turn ends (`messageIdleNotifThresholdMs = 0`) and its background agents are done, `permission_prompt` after 6s of an unanswered permission dialog
          Notification = [
            {
              matcher = "idle_prompt|permission_prompt";

              hooks = [releaseInhibitor];
            }
          ];
        };

        # subagents aren't worth the quota they consume
        permissions.deny = [
          # keep-sorted start
          "Agent"
          "Workflow"
          # keep-sorted end
        ];

        # keep unused skills out of the listing every session sends to the model
        skillOverrides = {
          # keep-sorted start by_regex=\w.*
          "anthropic-skills:built-in-browser" = "off";
          "anthropic-skills:chrome-browser" = "off";
          "anthropic-skills:computer-use" = "off";
          "anthropic-skills:deep-research" = "off";
          "anthropic-skills:docs" = "off";
          "anthropic-skills:google-workspace" = "off";
          artifact-capabilities = "off";
          artifact-design = "off";
          artifact-diagramming = "off";
          auto-mode-setup = "off"; # disable the prompt to teach auto mode about the environment
          claude-in-chrome = "off"; # the browser is driven through playwright
          dataviz = "off";
          fewer-permission-prompts = "off";
          keybindings-help = "off";
          plugin-authoring = "off";
          run = "off";
          schedule = "off";
          security-review = "off";
          update-config = "off"; # claude settings come from this file, `settings.json` is overwritten on activation
          # keep-sorted end

          # still typable as `/name`
          # keep-sorted start
          code-review = "user-invocable-only";
          init = "user-invocable-only";
          simplify = "user-invocable-only";
          # keep-sorted end
        };
      };
    };
  };

  services.syncthing.settings.folders.claude = {
    path = "${config.xdg.userDirs.documents}/claude";

    devices = [
      # keep-sorted start
      "hilonix"
      "lelonix"
      "zikkkix"
      # keep-sorted end

      # always-on relay between devices; only holds the encrypted data
      {
        name = "de0";

        encryptionPasswordFile = config.sops.secrets."apps/syncthing/folders/claude/encryption-password".path;
      }
    ];
  };

  home = let
    settingsPath = "${config.programs.claude-code.configDir}/settings.json";
  in {
    file = let
      syncedPath = config.services.syncthing.settings.folders.claude.path;
    in
      {
        ${settingsPath}.enable = false; # keep the generated settings source without linking an immutable user config

        "${config.programs.claude-code.configDir}/projects".source = config.lib.file.mkOutOfStoreSymlink "${syncedPath}/projects";

        "${syncedPath}/.stignore".text = "/projects/-tmp*"; # sessions started in `/tmp` are throwaway
      }
      # share user skills and session history, with the rewind checkpoints, plans, tasks and hook env a resumed session needs
      // lib.genAttrs' [
        # keep-sorted start
        "file-history"
        "plans"
        "projects"
        "session-env"
        "skills"
        "tasks"
        # keep-sorted end
      ] (name: lib.nameValuePair "${gatewayConfigDir}/${name}" {source = config.lib.file.mkOutOfStoreSymlink "${config.programs.claude-code.configDir}/${name}";});

    activation = {
      writeClaudeCodeConfig = let
        mergeSettingsFilter = lib.escapeShellArg ''
          (
            .[0]
            # keep only settings managed dynamically by claude
            | with_entries(select(.key | IN("model", "modelSettings")))
          )
          # apply the declarative settings with higher priority
          * .[1]
        '';
      in
        lib.hm.dag.entryAfter ["linkGeneration"] ''
          settings_file=${lib.escapeShellArg config.home.file.${settingsPath}.source}

          # the gateway's config dir keeps a settings file of its own: `/model` saves the pick as the default for new sessions, and native sessions can't run a gateway model
          for config_file in ${lib.escapeShellArgs [settingsPath "${gatewayConfigDir}/settings.json"]}; do
            if [[ -s $config_file ]]; then
              run ${pkgs.runtimeShell} -c '${lib.getExe pkgs.jq} --slurp "$1" $2 $3 | ${lib.getExe' pkgs.moreutils "sponge"} $2' -- ${mergeSettingsFilter} $config_file $settings_file
            else
              run ${lib.getExe' pkgs.coreutils "install"} -D --mode=600 $settings_file $config_file
            fi
          done
        '';

      # these are only read from the global config, which claude itself keeps writing
      writeClaudeCodeGlobalConfig = let
        globalConfig = pkgs.writeText "claude-code-global-config.json" (builtins.toJSON {
          autoConnectIde = true;

          lspRecommendationDisabled = true; # the lsp plugin recommendation ignores `lspServers`

          hasSeenAutoModeOutsideReadPrompt = true; # skip the one-time auto mode prompt on reads outside the working directories
          autoModeClassifierBillingNoticeAcknowledgedAt = 253402300799000; # the gateway fallback notice comes back every 24h and holds a session until a key is pressed; acknowledge it until 9999

          messageIdleNotifThresholdMs = 0; # notify as soon as a turn ends instead of after a minute of idling
        });
      in
        lib.hm.dag.entryAfter ["linkGeneration"] ''
          config_file=${lib.escapeShellArg "${config.home.homeDirectory}/.claude.json"}
          global_config_file=${lib.escapeShellArg globalConfig}

          if [[ -s $config_file ]]; then
            run ${pkgs.runtimeShell} -c '${lib.getExe pkgs.jq} --slurp ".[0] * .[1]" $1 $2 | ${lib.getExe' pkgs.moreutils "sponge"} $1' -- $config_file $global_config_file
          else
            run ${lib.getExe' pkgs.coreutils "install"} -D --mode=600 $global_config_file $config_file
          fi
        '';

      # gateway sessions share the native global config (trust, `/config`, onboarding); not `home.file`: claude follows one symlink hop when writing, and home-manager's link leads into the read-only store
      linkClaudeCodeGatewayGlobalConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
        run ${lib.getExe' pkgs.coreutils "ln"} --symbolic --force --no-target-directory ${lib.escapeShellArg "${config.home.homeDirectory}/.claude.json"} ${lib.escapeShellArg "${gatewayConfigDir}/.claude.json"}
      '';
    };
  };

  systemd.user = {
    # a lease on the inhibitor, renewed by every prompt and tool call; Esc interrupts a turn without any hook and keeps `idle_prompt` from coming, so only the lease releases it then
    timers."claude-inhibit@" = {
      Unit = {
        Description = "Claude sleep inhibitor lease";

        # brings the inhibitor up and goes down with it, whatever stops it
        BindsTo = ["claude-inhibit@%i.service"];
        After = ["claude-inhibit@%i.service"]; # with the ordering the lease is never active without the inhibitor
      };

      Timer = {
        OnActiveSec = "15min"; # a foreground command runs up to 10min without any hook

        Unit = "claude-inhibit-expired@%i.target";
      };
    };

    # stops the inhibitor once the lease runs out
    targets."claude-inhibit-expired@".Unit = {
      Description = "Claude sleep inhibitor lease expired";

      Conflicts = ["claude-inhibit@%i.service"];

      StopWhenUnneeded = true; # otherwise it stays active after the lease runs out, until the next turn of that claude process or for good once it exits
    };

    services = let
      daemonService = {
        # not `finalPackage`: its `--plugin-dir` flags come first and turn `daemon run` into a prompt
        ExecStart = "${lib.getExe config.programs.claude-code.package} daemon run";

        KillMode = "process"; # the default `control-group` kills the sessions along with the daemon; `process` leaves them for the new daemon to adopt
      };
    in {
      # held by the claude hooks for the claude process given as the instance; `waitpid` also releases it when that process dies mid-turn
      "claude-inhibit@" = {
        Unit.Description = "Claude sleep inhibitor";

        Service.ExecStart = "${lib.getExe' pkgs.kdePackages.kde-cli-tools "kde-inhibit"} --power --screenSaver ${lib.getExe' pkgs.util-linux "waitpid"} %i"; # `--power` blocks suspend, `--screenSaver` dimming and turning the displays off
      };

      # the unit name claude looks for before spawning a daemon of its own
      "com.anthropic.claude-daemon" = {
        Install.WantedBy = ["default.target"]; # claude starts the unit itself only when a server-side flag is set; otherwise its first client spawns a daemon of its own

        Unit.Description = "Claude daemon";

        Service = daemonService;
      };

      # with `CLAUDE_CONFIG_DIR` claude looks for no unit and connects to whichever daemon serves that config dir; run one for the gateway's
      claude-gateway-daemon = {
        Install.WantedBy = ["default.target"]; # otherwise the first gateway client spawns a transient daemon in its terminal's cgroup

        Unit = {
          Description = "Claude gateway daemon";

          After = ["sops-nix.service"];
        };

        Service = lib.mkMerge [
          daemonService

          {Environment = "CLAUDE_CODE_GATEWAY=1";}
        ];
      };
    };
  };
}
