{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  environment.systemPackages = [
    # keep-sorted start
    pkgs.lenovo-legion
    # keep-sorted end
  ];
}
