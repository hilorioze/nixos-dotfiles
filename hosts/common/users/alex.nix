{config, ...}: {
  sops.secrets."users/alex/hashed-password".neededForUsers = true;

  users.users.alex = {
    isNormalUser = true;

    hashedPasswordFile = config.sops.secrets."users/alex/hashed-password".path;
  };

  home-manager.users.alex.imports = [../../../home/alex];
}
