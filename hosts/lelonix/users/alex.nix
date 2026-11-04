{
  imports = [../../common/users/alex.nix];

  home-manager.users.alex.imports = [../../../home/alex/hosts/lelonix];
}
