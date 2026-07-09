{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  bsManagerConfigPath = "${config.xdg.configHome}/bs-manager/config.json";

  bsManagerSettingsFile = (pkgs.formats.json {}).generate "bs-manager-settings.json" {
    installation-folder = "/mnt/vol/Games";

    proton-folder = pkgs.proton-ge-bin.steamcompattool;
  };
in {
  home = {
    packages = [pkgs.bs-manager];

    activation.writeBsManagerConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      config_file=${lib.escapeShellArg bsManagerConfigPath}
      settings_file=${lib.escapeShellArg bsManagerSettingsFile}

      if [[ -s $config_file ]]; then
        run ${pkgs.runtimeShell} -c '${lib.getExe pkgs.jq} --slurp ".[0] * .[1]" $1 $2 | ${lib.getExe' pkgs.moreutils "sponge"} $1' -- $config_file $settings_file
      else
        run ${lib.getExe' pkgs.coreutils "install"} -D $settings_file $config_file
      fi
    '';
  };
}
