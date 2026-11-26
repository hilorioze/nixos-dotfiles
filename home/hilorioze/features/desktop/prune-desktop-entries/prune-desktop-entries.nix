{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  # drop launchers of uninstalled programs; waydroid, wine and the like never remove the ones they write
  home.activation.pruneDesktopEntries = let
    pruneDesktopEntries = pkgs.writers.writePython3 "prune-desktop-entries" {
      doCheck = false; # treefmt lints the script with ruff
    } (builtins.readFile ./prune-desktop-entries.py);
  in
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      # look the programs up in the session `PATH`; `/etc/set-environment` expands `XDG_STATE_HOME` and `TERM`, which the activation lacks
      (set +o nounset && source /etc/set-environment && run ${pruneDesktopEntries} ${config.xdg.dataHome}/applications)
    '';
}
