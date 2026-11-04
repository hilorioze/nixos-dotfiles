{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/nh.nix];

  home.shellAliases = {
    ns = "${lib.getExe config.programs.nh.package} os switch";
    nca = "${lib.getExe config.programs.nh.package} clean all";
  };
}
