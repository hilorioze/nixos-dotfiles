{
  # keep-sorted start
  inputs,
  lib',
  outputs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "hm-bak";

    extraSpecialArgs = {
      inherit inputs;
      inherit lib';

      inherit outputs;
    };
  };
}
