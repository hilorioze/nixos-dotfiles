{
  imports = [../../../common/features/security/sops.nix];

  sops.defaultSopsFile = ../../secrets.yaml;
}
