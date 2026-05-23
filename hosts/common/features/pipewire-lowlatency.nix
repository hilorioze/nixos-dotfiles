{
  # keep-sorted start
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    # keep-sorted end
  ];

  services.pipewire.lowLatency.enable = true;
}
