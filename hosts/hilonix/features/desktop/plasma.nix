{pkgs, ...}: {
  imports = [../../../common/features/desktop/plasma.nix];

  environment.plasma6.excludePackages = [pkgs.kdePackages.discover];
}
