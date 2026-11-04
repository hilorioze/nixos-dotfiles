{inputs, ...}: {
  imports = [
    # keep-sorted start
    ../../../features/desktop/gtk.nix
    ../../../features/desktop/xdg/autostart.nix
    ../../../features/desktop/xdg/user-dirs.nix
    # keep-sorted end

    (inputs.import-tree.filterNot (path: path == "/default.nix") ./.) # this file is left out so it doesn't import itself
  ];
}
