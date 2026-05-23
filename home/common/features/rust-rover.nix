{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  home.packages = [
    # keep-sorted start
    pkgs.jetbrains.rust-rover
    # keep-sorted end
  ];
}
