{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets."users/hilorioze/hashed-password" = {
    neededForUsers = true;

    sopsFile = lib.mkDefault ../secrets.yaml;
  };

  users.users.hilorioze = {
    uid = 1000;
    isNormalUser = true;

    shell = pkgs.zsh;

    hashedPasswordFile = config.sops.secrets."users/hilorioze/hashed-password".path;
    openssh.authorizedKeys.keys = ["sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGuhtLQydHgRNOPGqel/FI2vQ9JtgHN9afnoi2dMnw3EAAAABHNzaDo= me@hilorioze.com"];

    extraGroups = ["wheel"];
  };

  home-manager.users.hilorioze.imports = [../../../home/hilorioze];
}
