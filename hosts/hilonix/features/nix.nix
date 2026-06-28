{
  # keep-sorted start
  lib,
  outputs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/nix.nix];

  nix.settings = let
    ncpsHostName = outputs.nixosConfigurations.fakesynology-nixos.config.services.ncps.cache.hostName;
  in {
    extra-substituters = lib.mkBefore ["http://${ncpsHostName}:${lib.last (lib.splitString ":" outputs.nixosConfigurations.fakesynology-nixos.config.services.traefik.staticConfigOptions.entryPoints.ncps.address)}?priority=0"];

    extra-trusted-public-keys = lib.mkBefore ["${ncpsHostName}-1:U5e1924CMNiv9lk5HFYGHm7TQtp1KvnFz8g9qDIuY60="];
  };
}
