{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.claude-code = {
    enable = true;

    package = pkgs.unstablePkgs.claude-code;

    enableMcpIntegration = true;

    settings = {
      attribution = false; # requires claude code 2.1.281+, which `unstablePkgs` always provides

      statusLine = {
        type = "command";

        command = lib.getExe pkgs.claude-code-status-line;
      };
    };
  };

  home = let
    settingsPath = "${config.programs.claude-code.configDir}/settings.json";
  in {
    file.${settingsPath}.enable = false; # keep the generated settings source without linking an immutable user config

    activation.writeClaudeCodeConfig = let
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
  };
}
