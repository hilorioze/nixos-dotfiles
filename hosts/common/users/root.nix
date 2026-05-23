{config, ...}: {
  sops.secrets."users/root/hashed-password".neededForUsers = true;

  users.users.root.hashedPasswordFile = config.sops.secrets."users/root/hashed-password".path;
}
