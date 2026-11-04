{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home = {
    packages = [pkgs.devenv];

    shellAliases.deu = "${lib.getExe pkgs.devenv} update";
  };
}
