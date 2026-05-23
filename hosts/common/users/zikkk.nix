{config, ...}: {
  sops.secrets."users/zikkk/hashed-password".neededForUsers = true;

  users.users.zikkk = {
    isNormalUser = true;

    hashedPasswordFile = config.sops.secrets."users/zikkk/hashed-password".path;
  };

  home-manager.users.zikkk.imports = [../../../home/zikkk];
}
