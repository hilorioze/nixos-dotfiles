{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home = {
    packages = [pkgs.ayugram-desktop];

    # ayugram writes the options toggled in its experimental settings into the same file
    activation.writeAyugramExperimentalOptions = let
      options = pkgs.writeText "ayugram-experimental-options.json" (builtins.toJSON {
        skip-url-scheme-register = true; # ayugram doesn't recognize its packaged `env DESKTOPINTEGRATION=1` launcher as the `tg://` handler and adds a new `userapp-*.desktop` after every update
      });
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        config_file=${config.xdg.dataHome}/AyuGramDesktop/tdata/experimental_options.json
        options_file=${options}

        if [[ -s $config_file ]]; then
          run ${pkgs.runtimeShell} -c '${lib.getExe pkgs.jq} --slurp ".[0] * .[1]" $1 $2 | ${lib.getExe' pkgs.moreutils "sponge"} $1' -- $config_file $options_file
        else
          run ${lib.getExe' pkgs.coreutils "install"} -D $options_file $config_file
        fi
      '';
  };
}
