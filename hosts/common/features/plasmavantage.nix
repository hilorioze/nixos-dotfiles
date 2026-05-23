{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  environment.systemPackages = [
    # keep-sorted start
    pkgs.plasmavantage
    # keep-sorted end
  ];
}
