{
  lib,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs._7zz

    # ark looks for `7z`, while `_7zz` only installs `7zz`
    (pkgs.linkFarm "7z" {"bin/7z" = lib.getExe pkgs._7zz;})
  ];
}
