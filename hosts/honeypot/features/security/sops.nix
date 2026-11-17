{inputs, ...}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    age = {
      keyFile = "/etc/sops/age/keys.txt";
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];

    defaultSopsFile = ../../secrets.yaml;
  };
}
