{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  home.packages = [
    # keep-sorted start
    pkgs.heroic
    # keep-sorted end
  ];
}
