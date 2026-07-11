{
  # keep-sorted start
  lib,
  outputs,
  # keep-sorted end
  ...
}: let
  fakesynologyNixosConfig = outputs.nixosConfigurations.fakesynology-nixos.config;

  ncpsHostName = fakesynologyNixosConfig.services.ncps.cache.hostName;
in {
  nix.settings = {
    # keep `ncps` substituter lookups short when it is down, so `nix` commands do not wait on retries
    extra-substituters = lib.mkBefore ["http://${ncpsHostName}:${lib.last (lib.splitString ":" fakesynologyNixosConfig.services.traefik.staticConfigOptions.entryPoints.ncps.address)}?priority=1&retry-attempts=1"];

    extra-trusted-public-keys = lib.mkBefore ["${ncpsHostName}-1:U5e1924CMNiv9lk5HFYGHm7TQtp1KvnFz8g9qDIuY60="];
  };
}
