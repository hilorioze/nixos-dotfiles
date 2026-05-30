{inputs, ...}: {
  imports = [inputs.nix-gaming.nixosModules.pipewireLowLatency];

  services.pipewire.lowLatency.enable = true;
}
