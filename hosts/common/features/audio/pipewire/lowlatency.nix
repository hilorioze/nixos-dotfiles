{
  # keep-sorted start
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [inputs.nix-gaming.nixosModules.pipewireLowLatency];

  services.pipewire = {
    lowLatency.enable = true;

    # the module sets quality 1 for native clients, which cuts 44.1 khz audio from 15.4 khz to save less than half a millisecond; 4 is pipewire's default
    extraConfig.client."99-lowlatency"."stream.properties"."resample.quality" = lib.mkForce 4;
  };
}
