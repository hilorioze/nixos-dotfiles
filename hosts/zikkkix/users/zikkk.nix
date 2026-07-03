{
  imports = [../../common/users/zikkk.nix];

  users.users.zikkk.extraGroups = [
    # keep-sorted start
    "gamemode"
    "networkmanager"
    "wheel"
    # keep-sorted end
  ];

  home-manager.users.zikkk.imports = [../../../home/zikkk/hosts/zikkkix];
}
