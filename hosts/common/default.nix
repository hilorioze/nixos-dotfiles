{outputs, ...}: {
  imports =
    [
      ./features
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;

    config.allowUnfree = true;
  };
}
