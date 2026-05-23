{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/chromium.nix];

  programs.chromium = {
    package = pkgs.google-chrome;

    extensions = lib.mkForce []; # google chrome only loads external extensions from system-managed directories, which home manager does not manage
  };
}
