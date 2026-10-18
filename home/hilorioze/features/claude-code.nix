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

      agents = {
        # keep-sorted start block=yes newline_separated=yes group_prefixes='';
        # a broad search reads far more than it finds; gemini behind the gateway does the reading outside claude's quota and returns only the findings
        sweep = ''
          ---
          name: sweep
          description: Sweeps many files, logs or command outputs and reports only the findings, such as repository-wide searches, journal and log trawls, or comparing configs across hosts. Use it when answering needs a lot of reading but you only need the conclusion; pass the question and where to look. Not for edits, code review or design decisions.
          tools: Read, Bash
          model: antigravity/gemini-3.8-flash-high
          ---

          Search, read and run read-only commands to answer the question you are given. Never change files, services or remote state. Report the findings with exact file paths, line numbers, command lines and verbatim quotes of the lines that matter, so the caller can act on them without rereading. Say where you searched and found nothing instead of guessing. Stop as soon as the findings answer the question.
        '';

        # an image read by the session model stays in its context for the rest of the session; gemini behind the gateway reads it outside claude's quota and returns only text
        vision = ''
          ---
          name: vision
          description: Describes images (screenshots, photos, diagrams, scanned documents) and answers questions about them. Use it instead of reading an image file yourself; pass the file path and what you need to know. Read the image yourself only when the task depends on fine visual detail, such as layout, fonts or colours.
          tools: Read
          model: antigravity/gemini-3.8-flash-high
          ---

          Read the image files you are given and answer the question about them. Transcribe all visible text that matters to the question verbatim, including error messages, code, log lines and UI labels. Describe layout and visual state only as far as the question needs. Say plainly when something is unreadable or cut off instead of guessing.
        '';

        # browser snapshots run to tens of thousands of tokens each and stay in the session model's context; gemini behind the gateway browses outside claude's quota and returns only what was asked
        # no `WebSearch`: it runs as a server tool of the agent's own model, and gemini returns no results
        web = ''
          ---
          name: web
          description: Reads web pages and answers questions about them, browsing in the user's chromium through playwright when a page needs javascript, a login or several steps to reach. Use it instead of browsing yourself; pass the urls or the site and what you need to know. Search the web yourself and hand it the urls.
          tools: WebFetch, ${
            lib.concatMapStringsSep ", " (tool: "mcp__plugin_claude-code-home-manager_playwright__browser_${tool}") [
              # keep-sorted start
              "click"
              "close"
              "evaluate"
              "navigate"
              "navigate_back"
              "press_key"
              "snapshot"
              "tabs"
              "take_screenshot"
              "type"
              "wait_for"
              # keep-sorted end
            ]
          }
          model: antigravity/gemini-3.8-flash-high
          ---

          Fetch or browse the pages you are given and answer the question about them. Quote the facts that matter verbatim, such as versions, prices, dates, commands and error messages, and give the url each one came from. Don't submit forms, post, buy or change anything on a site. Say plainly when a page is unreachable, empty or behind a login instead of guessing. Stop as soon as the pages answer the question; read a page once instead of snapshotting it piece by piece.
        '';
        # keep-sorted end
      };

      settings = {
        autoCompactWindow = 220000; # actually triggers at 187k (reserves 20k output + 13k buffer)

        autoMemoryDirectory = "${config.services.syncthing.settings.folders.sync.path}/claude/memory"; # global memory; shared between hosts

        worktree.bgIsolation = "none"; # let background sessions edit the main checkout

        attribution = false; # requires claude 2.1.281+, which `unstablePkgs` always provides

        awaySummaryEnabled = false; # disable the "※ recap" block generated after being away
        promptSuggestionEnabled = false; # disable the guess of the next message, a model request over the whole conversation after every reply

        promptCacheTtl = "1h"; # claude sets 1h only for a claude.ai login; with the gateway's token it falls back to 5m, and every break over 5 min writes the whole context again

        preferredNotifChannel = "terminal_bell"; # `auto` ignores konsole; bell triggers a notification

        switchModelsOnFlag = true; # switch to the fallback model without asking when the safeguards flag a session

        env.ENABLE_TOOL_SEARCH = "true"; # behind a base url other than anthropic's, claude stops deferring mcp tools and sends every tool definition with each request

        statusLine = {
          type = "command";

          command = lib.getExe pkgs.claude-code-status-line;
        };

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
          # keep-sorted start
          autoConnectIde = true; # automatically connect to a running ide from an external terminal
          hasSeenAutoModeOutsideReadPrompt = true; # skip the one-time auto mode prompt on reads outside the working directories
          lspRecommendationDisabled = true; # the lsp plugin recommendation ignores `lspServers`
          messageIdleNotifThresholdMs = 0; # notify as soon as a turn ends instead of after a minute of idling
          # keep-sorted end
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

  # the unit name claude looks for before spawning a daemon of its own
  systemd.user.services."com.anthropic.claude-daemon" = {
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
}
