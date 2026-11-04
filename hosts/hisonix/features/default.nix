{inputs, ...}: {
  imports = [
    # keep-sorted start
    ../../common/features/avahi.nix
    ../../common/features/partition-manager.nix
    ../../common/features/plasma.nix
    # keep-sorted end

    (inputs.import-tree.filterNot (path: path == "/default.nix") ./.) # this file is left out so it doesn't import itself
  ];
}
