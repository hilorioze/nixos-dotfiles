{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs = {
    git.ignores = [".claude/worktrees/"]; # worktrees are nested repositories, which `git add --all` would stage as gitlinks

    claude-code = {
      enable = true;

      package = pkgs.claude-code-with-node; # the wakatime plugin hooks need node

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
        attribution = false; # requires claude code 2.1.281+, which `unstablePkgs` always provides

        autoCompactWindow = 280000;

        autoMemoryDirectory = "${config.services.syncthing.settings.folders.sync.path}/claude/memory"; # global memory; shared between hosts

        statusLine = {
          type = "command";

          command = lib.getExe pkgs.claude-code-status-line;
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
            # keep only settings managed dynamically by claude code
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

      # these are only read from the global config, which claude code itself keeps writing
      writeClaudeCodeGlobalConfig = let
        globalConfig = pkgs.writeText "claude-code-global-config.json" (builtins.toJSON {
          # keep-sorted start
          autoConnectIde = true; # automatically connect to a running ide from an external terminal
          hasSeenAutoModeOutsideReadPrompt = true; # the answer to the first read outside the working directories
          lspRecommendationDisabled = true; # the lsp plugin recommendation ignores `lspServers`
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
}
