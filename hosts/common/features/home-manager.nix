{
  # keep-sorted start
  inputs,
  outputs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "hm-bak";

    extraSpecialArgs = {inherit inputs outputs;};
  };
}
