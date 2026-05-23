{
  imports = [
    # keep-sorted start
    ../../common/users/alex.nix
    # keep-sorted end
  ];

  users.users.alex.extraGroups = [
    # keep-sorted start
    "gamemode"
    "networkmanager"
    "wheel"
    # keep-sorted end
  ];

  home-manager.users.alex.imports = [
    # keep-sorted start
    ../../../home/alex/hosts/lelonix
    # keep-sorted end
  ];
}
