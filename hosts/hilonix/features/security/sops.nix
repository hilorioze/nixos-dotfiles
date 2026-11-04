{pkgs, ...}: {
  imports = [../../../common/features/security/sops.nix];

  sops = {
    age.plugins = [pkgs.age-plugin-tpm];

    defaultSopsFile = ../../secrets.yaml;
  };
}
