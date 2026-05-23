{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  home.packages = [
    # keep-sorted start
    pkgs.kdePackages.filelight
    # keep-sorted end
  ];
}
