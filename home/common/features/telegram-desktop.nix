{
  # keep-sorted start
  inputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.packages = [inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.telegram-desktop];
}
