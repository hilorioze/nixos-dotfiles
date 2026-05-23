{
  sops.secrets."users/hilorioze/hashed-password".sopsFile = ../secrets.yaml;

  users.users.hilorioze.extraGroups = [
    # keep-sorted start
    "gamemode"
    "networkmanager"
    # keep-sorted end
  ];

  home-manager.users.hilorioze.imports = [../../../home/hilorioze/hosts/zikkkix];
}
