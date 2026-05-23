{pkgs, ...}: {
  imports = [../../common/features/plasma.nix];

  environment.plasma6.excludePackages = [pkgs.kdePackages.discover];
}
