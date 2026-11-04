{inputs, ...}: {
  imports = [
    # keep-sorted start
    ../../common/features/desktop/plasma.nix
    ../../common/features/network/avahi.nix
    ../../common/features/storage/partition-manager.nix
    # keep-sorted end

    (inputs.import-tree.filterNot (path: path == "/default.nix") ./.) # this file is left out so it doesn't import itself
  ];
}
