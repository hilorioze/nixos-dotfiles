{
  sops.secrets."users/hilorioze/hashed-password".sopsFile = ../secrets.yaml;

  users.users.hilorioze.extraGroups = [
    # keep-sorted start
    "dialout"
    "gamemode"
    "networkmanager"
    # keep-sorted end
  ];

  home-manager.users.hilorioze.imports = [
    # keep-sorted start
    ../../../home/hilorioze/hosts/lelonix
    # keep-sorted end
  ];
}
