{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    ../../common/features/plasma.nix
    # keep-sorted end
  ];

  environment.plasma6.excludePackages = [
    # keep-sorted start
    pkgs.kdePackages.discover
    # keep-sorted end
  ];
}
