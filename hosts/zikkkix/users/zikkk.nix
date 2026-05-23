{
  imports = [../../common/users/zikkk.nix];

  sops.secrets."users/zikkk/hashed-password".sopsFile = ../secrets.yaml;

  users.users.zikkk.extraGroups = [
    # keep-sorted start
    "gamemode"
    "networkmanager"
    "wheel"
    # keep-sorted end
  ];

  home-manager.users.zikkk.imports = [../../../home/zikkk/hosts/zikkkix];
}
