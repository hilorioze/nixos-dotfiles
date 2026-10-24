{
  # keep-sorted start
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets."apps/cliproxyapi/inference-key" = {};

  programs = {
    git.ignores = [".claude/worktrees/"]; # worktrees are nested repositories, which `git add --all` would stage as gitlinks

    claude-code = {
      enable = true;

      package = pkgs.symlinkJoin {
        name = "claude-code";

        inherit (pkgs.claude-code-with-node) version;

        paths = [pkgs.claude-code-with-node]; # the wakatime plugin hooks need node

        nativeBuildInputs = [pkgs.makeWrapper];

        # `CLAUDE_CODE_DIRECT=1` skips the gateway, which adds the models of every cliproxyapi account to `/model`
        postBuild = ''
          wrapProgram $out/bin/${pkgs.claude-code-with-node.meta.mainProgram} \
            --run ${lib.escapeShellArg ''
            picker=()

            if [[ -n ''${CLAUDE_CODE_DIRECT-} ]]; then
              unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN # a claude started from a gateway session inherits them
            else
              # cliproxyapi runs only on de0: a second instance would rotate the accounts' refresh tokens out from under it
              export ANTHROPIC_BASE_URL=https://claude-code-gateway.${outputs.nixosConfigurations.de0.config.networking.fqdn} ANTHROPIC_AUTH_TOKEN=$(<${config.sops.secrets."apps/cliproxyapi/inference-key".path})

              # claude reads the picker once, at launch; its quotas are laid out for this terminal
              if [[ -t 0 ]]; then
                read -r _ columns < <(${lib.getExe' pkgs.coreutils "stty"} size)

                # the key stays out of the process list
                if settings=$(${lib.getExe pkgs.curl} --fail --silent --max-time 3 --header @- "$ANTHROPIC_BASE_URL/model-picker?width=$columns" <<<"Authorization: Bearer $ANTHROPIC_AUTH_TOKEN"); then
                  picker=(--settings "$settings")
                fi
              fi
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

        modelSettings."antigravity/gemini-3.8-flash-high".autoCompactWindow = 1000000;

        autoMemoryDirectory = "${config.services.syncthing.settings.folders.sync.path}/claude/memory"; # global memory; shared between hosts

        worktree.bgIsolation = "none"; # let background sessions edit the main checkout

        attribution = false; # requires claude 2.1.281+, which `unstablePkgs` always provides

        awaySummaryEnabled = false; # disable the "※ recap" block generated after being away
        promptSuggestionEnabled = false; # disable the guess of the next message, a model request over the whole conversation after every reply

        promptCacheTtl = "1h"; # claude sets 1h only for a claude.ai login; with the gateway's token it falls back to 5m, and every break over 5 min writes the whole context again

        preferredNotifChannel = "terminal_bell"; # `auto` ignores konsole; bell triggers a notification

        switchModelsOnFlag = true; # switch to the fallback model without asking when the safeguards flag a session

        env.ENABLE_TOOL_SEARCH = "true"; # behind a base url other than anthropic's, claude stops deferring mcp tools and sends every tool definition with each request

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
          "anthropic-skills:docs" = "off";
          "anthropic-skills:google-workspace" = "off";
          artifact-capabilities = "off";
          artifact-design = "off";
          artifact-diagramming = "off";
          auto-mode-setup = "off"; # disable the prompt to teach auto mode about the environment
          claude-in-chrome = "off"; # the browser is driven through playwright
          dataviz = "off";
          keybindings-help = "off";
          plugin-authoring = "off";
          run = "off";
          update-config = "off"; # claude settings come from this file, `settings.json` is overwritten on activation
          # keep-sorted end

          # still typable as `/name`
          # keep-sorted start by_regex=\w.*
          "anthropic-skills:deep-research" = "user-invocable-only";
          code-review = "user-invocable-only";
          fewer-permission-prompts = "user-invocable-only";
          init = "user-invocable-only";
          schedule = "user-invocable-only";
          security-review = "user-invocable-only";
          simplify = "user-invocable-only";
          # keep-sorted end
        };
      };
    };
  };

  home = let
    settingsPath = "${config.programs.claude-code.configDir}/settings.json";
  in {
    file.${settingsPath}.enable = false; # keep the generated settings source without linking an immutable user config

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
          config_file=${lib.escapeShellArg settingsPath}
          settings_file=${lib.escapeShellArg config.home.file.${settingsPath}.source}

          if [[ -s $config_file ]]; then
            run ${pkgs.runtimeShell} -c '${lib.getExe pkgs.jq} --slurp "$1" $2 $3 | ${lib.getExe' pkgs.moreutils "sponge"} $2' -- ${mergeSettingsFilter} $config_file $settings_file
          else
            run ${lib.getExe' pkgs.coreutils "install"} -D --mode=600 $settings_file $config_file
          fi
        '';

      # these are only read from the global config, which claude itself keeps writing
      writeClaudeCodeGlobalConfig = let
        globalConfig = pkgs.writeText "claude-code-global-config.json" (builtins.toJSON {
          autoConnectIde = true; # automatically connect to a running ide from an external terminal

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

    services = {
      # held by the claude hooks for the claude process given as the instance; `waitpid` also releases it when that process dies mid-turn
      "claude-inhibit@" = {
        Unit.Description = "Claude sleep inhibitor";

        Service.ExecStart = "${lib.getExe' pkgs.kdePackages.kde-cli-tools "kde-inhibit"} --power --screenSaver ${lib.getExe' pkgs.util-linux "waitpid"} %i"; # `--power` blocks suspend, `--screenSaver` dimming and turning the displays off
      };

      # the unit name claude looks for before spawning a daemon of its own
      "com.anthropic.claude-daemon" = {
        Install.WantedBy = ["default.target"]; # claude starts the unit itself only when a server-side flag is set; otherwise its first client spawns a daemon of its own

        Unit = {
          Description = "Claude daemon";

          After = ["sops-nix.service"]; # the package reads the gateway key once, when the daemon starts
        };

        Service = {
          # not `finalPackage`: its `--plugin-dir` flags come first and turn `daemon run` into a prompt
          ExecStart = "${lib.getExe config.programs.claude-code.package} daemon run";

          KillMode = "process"; # the default `control-group` kills the sessions along with the daemon; `process` leaves them for the new daemon to adopt
        };
      };
    };
  };
}
