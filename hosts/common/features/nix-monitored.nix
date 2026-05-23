{
  # keep-sorted start
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    inputs.nix-monitored.nixosModules.default
    # keep-sorted end
  ];

  nix.monitored.enable = true;
}
