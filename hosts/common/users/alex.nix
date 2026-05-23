{
  # keep-sorted start
  config,
  # keep-sorted end
  ...
}: {
  sops.secrets."users/alex/hashed-password".neededForUsers = true;

  users.users.alex = {
    isNormalUser = true;

    hashedPasswordFile = config.sops.secrets."users/alex/hashed-password".path;
  };

  home-manager.users.alex.imports = [
    # keep-sorted start
    ../../../home/alex
    # keep-sorted end
  ];
}
