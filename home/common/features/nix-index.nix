{
  # keep-sorted start
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    inputs.nix-index-database.homeModules.default
    # keep-sorted end
  ];

  programs.nix-index.enable = true;
}
