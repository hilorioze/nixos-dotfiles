{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  home.packages = [
    # keep-sorted start
    pkgs.bruno
    # keep-sorted end
  ];
}
