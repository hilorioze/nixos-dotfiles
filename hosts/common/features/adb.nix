{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  environment.systemPackages = [
    # keep-sorted start
    pkgs.android-tools
    # keep-sorted end
  ];
}
