{
  # keep-sorted start
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    inputs.stylix.nixosModules.stylix
    # keep-sorted end
  ];

  stylix = {
    enable = true;

    homeManagerIntegration.autoImport = false; # who the fuck came up with this?
  };
}
