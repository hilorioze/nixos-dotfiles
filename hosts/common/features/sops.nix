{
  # keep-sorted start
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    age = {
      keyFile = "/etc/sops/age/keys.txt";
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];

    defaultSopsFile = lib.mkDefault ../secrets.yaml;
  };
}
