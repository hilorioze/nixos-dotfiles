{
  sops.secrets."users/hilorioze/hashed-password".sopsFile = ../secrets.yaml;

  users.users.hilorioze.extraGroups = [
    # keep-sorted start
    "dialout"
    "gamemode"
    "networkmanager"
    "uinput" # required by deadlocked
    # keep-sorted end
  ];

  home-manager.users.hilorioze.imports = [../../../home/hilorioze/hosts/lelonix];
}
