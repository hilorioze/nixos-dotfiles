{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.antigravity-cli = {
    enable = true;

    package = pkgs.unstablePkgs.antigravity-cli;

    enableMcpIntegration = true;

    settings = {
      allowNonWorkspaceAccess = true;

      artifactReviewPolicy = "always-proceed";
      toolPermission = "always-proceed";

      enableTelemetry = false;
      notifications = true;
    };
  };

  home = {
    file.".gemini/antigravity-cli/settings.json".enable = false; # keep the generated settings source without linking an immutable user config

    activation.writeAntigravityConfig = let
      mergeSettingsFilter = lib.escapeShellArg ''
        (
          .[0]
          # keep only settings managed dynamically by antigravity
          | with_entries(select(.key | IN("model", "trustedWorkspaces")))
        )
        # apply the declarative settings with higher priority
        * .[1]
      '';
    in
      lib.hm.dag.entryAfter ["linkGeneration"] ''
        config_file=${lib.escapeShellArg "${config.home.homeDirectory}/.gemini/antigravity-cli/settings.json"}
        settings_file=${lib.escapeShellArg config.home.file.".gemini/antigravity-cli/settings.json".source}

        if [[ -s $config_file ]]; then
          run ${pkgs.runtimeShell} -c '${lib.getExe pkgs.jq} --slurp "$1" $2 $3 | ${lib.getExe' pkgs.moreutils "sponge"} $2' -- ${mergeSettingsFilter} $config_file $settings_file
        else
          run ${lib.getExe' pkgs.coreutils "install"} -D --mode=600 $settings_file $config_file
        fi
      '';
  };
}
