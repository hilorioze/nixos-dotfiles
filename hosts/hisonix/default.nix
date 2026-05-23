{
  # keep-sorted start
  config,
  lib,
  modulesPath,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"
    "${modulesPath}/installer/cd-dvd/latest-kernel.nix"
    # keep-sorted end

    ../common

    ./features
  ];

  isoImage.edition = "plasma6";

  image.baseName = lib.mkForce config.networking.hostName;

  networking.hostName = "hisonix";

  nixpkgs.hostPlatform.system = "x86_64-linux";
}
