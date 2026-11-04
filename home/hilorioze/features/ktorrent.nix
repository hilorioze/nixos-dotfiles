{pkgs, ...}: {
  home.packages = [
    pkgs.kdePackages.ktorrent
  ];
}
