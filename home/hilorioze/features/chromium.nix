{pkgs, ...}: {
  imports = [../../common/features/chromium.nix];

  programs.chromium.package = pkgs.ungoogled-chromium;
}
