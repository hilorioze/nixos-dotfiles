{inputs, ...}: {
  imports = [
    # keep-sorted start
    ../../../features/gtk.nix
    ../../../features/xdg-autostart.nix
    ../../../features/xdg-user-dirs.nix
    # keep-sorted end

    (inputs.import-tree.filterNot (path: path == "/default.nix") ./.) # this file is left out so it doesn't import itself
  ];
}
