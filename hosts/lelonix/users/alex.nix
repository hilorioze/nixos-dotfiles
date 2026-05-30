{
  imports = [../../common/users/alex.nix];

  users.users.alex.extraGroups = [
    # keep-sorted start
    "gamemode"
    "networkmanager"
    "wheel"
    # keep-sorted end
  ];

  home-manager.users.alex.imports = [../../../home/alex/hosts/lelonix];
}
