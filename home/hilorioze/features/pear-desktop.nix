{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home = {
    packages = [config.programs.pear-desktop.package];

    # pear-desktop keeps writing its window state and last url into the same file
    activation.writePearDesktopConfig = let
      settings = pkgs.writeText "pear-desktop-config.json" (builtins.toJSON {
        options.removeUpgradeButton = true;

        plugins = {
          # keep-sorted start
          album-color-theme.enabled = true;
          bypass-age-restrictions.enabled = true;
          quality-changer.enabled = true;
          sponsorblock.enabled = true;
          # keep-sorted end

          ambient-mode.enabled = false; # the default, kept as a guard: the app lags badly after staying open for days because its leaked frame sync timers pile up and keep redrawing video frames until a restart
        };
      });
    in
      lib.hm.dag.entryAfter ["linkGeneration"] ''
        config_file=${lib.escapeShellArg "${config.xdg.configHome}/YouTube Music/config.json"}
        settings_file=${lib.escapeShellArg settings}

        if [[ -s $config_file ]]; then
          run ${pkgs.runtimeShell} -c '${lib.getExe pkgs.jq} --slurp ".[0] * .[1]" $1 $2 | ${lib.getExe' pkgs.moreutils "sponge"} $1' -- $config_file $settings_file
        else
          run ${lib.getExe' pkgs.coreutils "install"} -D --mode=600 $settings_file $config_file
        fi
      '';
  };
}
