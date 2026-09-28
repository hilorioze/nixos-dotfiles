{outputs, ...}: {
  imports =
    [
      ./features
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  nixpkgs = {
    overlays = [outputs.overlays.default];

    config.allowUnfree = true;
  };
}
