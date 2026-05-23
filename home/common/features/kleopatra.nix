{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  home.packages = [
    # keep-sorted start
    pkgs.kdePackages.kleopatra
    # keep-sorted end
  ];
}
