{
  imports = [../../common/features/sops.nix];

  sops.defaultSopsFile = ../secrets.yaml;
}
