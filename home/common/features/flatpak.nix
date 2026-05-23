{
  # keep-sorted start
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    # keep-sorted end
  ];

  services.flatpak.enable = true;
}
