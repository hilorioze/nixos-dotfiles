{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
}
