{
  sops.secrets."users/hilorioze/hashed-password".sopsFile = ../secrets.yaml;

  home-manager.users.hilorioze.imports = [../../../home/hilorioze/hosts/ru0];
}
