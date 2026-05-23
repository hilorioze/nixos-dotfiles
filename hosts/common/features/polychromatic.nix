{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  environment.systemPackages = [
    # keep-sorted start
    pkgs.polychromatic
    # keep-sorted end
  ];
}
