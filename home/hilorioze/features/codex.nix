{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.codex = {
    enable = true;

    package = pkgs.unstablePkgs.codex;

    enableMcpIntegration = true;

    settings = {
      personality = "pragmatic";

      approvals_reviewer = "auto_review";

      features.memories = true;

      tui.status_line = [
        "current-dir"
        "model-with-reasoning"
        "five-hour-limit"
        "weekly-limit"
        "context-used"
        "session-id"
      ];
    };
  };

  home = {
    file.".codex/config.toml".enable = false; # keep the generated settings source without linking an immutable user config

    activation = {
      writeCodexConfig = let
        mergeSettingsFilter = lib.escapeShellArg ''
          (
            .[0]
            # keep only settings managed dynamically by codex
            | with_entries(select(.key | IN("model", "model_reasoning_effort", "projects", "tui")))
            # and keep only codex's model announcement state from `tui`
            | if .tui then .tui |= with_entries(select(.key == "model_availability_nux")) else . end
          )
          # apply the declarative settings with higher priority
          * .[1]
        '';
      in
        lib.hm.dag.entryAfter ["linkGeneration"] ''
          config_file=${lib.escapeShellArg "${config.home.homeDirectory}/.codex/config.toml"}
          settings_file=${lib.escapeShellArg config.home.file.".codex/config.toml".source}

          if [[ -s $config_file ]]; then
            run ${pkgs.runtimeShell} -c '${lib.getExe' pkgs.yq "tomlq"} --toml-output --slurp "$1" $2 $3 | ${lib.getExe' pkgs.moreutils "sponge"} $2' -- ${mergeSettingsFilter} $config_file $settings_file
          else
            run ${lib.getExe' pkgs.coreutils "install"} -D --mode=600 $settings_file $config_file
          fi
        '';

      # these settings are stored in the extension's VSCodium global state rather than `config.toml` or `settings.json`
      configureCodexExtension = let
        stateDirectory = "${config.xdg.configHome}/VSCodium/User/globalStorage";

        codexExtensionSettings = builtins.toJSON {
          persisted-atom-state = {
            # `none` and `minimal` are useless here because current models do not advertise them
            enabled-reasoning-efforts = [
              "low"
              "medium"
              "high"
              "xhigh"
              "max"
              "ultra"
            ];

            show-context-window-usage = true;

            show-ultra-in-model-picker-slider = true;
          };
        };
      in
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          run ${lib.getExe' pkgs.coreutils "mkdir"} --parents ${lib.escapeShellArg stateDirectory}

          run ${lib.getExe pkgs.sqlite} ${lib.escapeShellArg "${stateDirectory}/state.vscdb"} \
            "PRAGMA busy_timeout = 5000;" \
            "PRAGMA user_version = 1; /* match VSCodium's storage schema version when creating the database */" \
            "CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB);" \
            "INSERT OR IGNORE INTO ItemTable (key, value) VALUES ('openai.chatgpt', '{}');" \
            ${lib.escapeShellArg "UPDATE ItemTable SET value = json_patch(value, '${codexExtensionSettings}') WHERE key = 'openai.chatgpt';"}
        '';
    };
  };
}
