{pkgs, ...}: {
  imports = [../../common/features/sops.nix];

  sops = {
    age.plugins = [pkgs.age-plugin-tpm];

    defaultSopsFile = ../secrets.yaml;
  };
}
