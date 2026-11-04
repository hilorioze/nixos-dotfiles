{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home = {
    packages = [pkgs.onlyoffice-desktopeditors];

    activation.copyFontsLocalShare = lib.hm.dag.entryAfter ["writeBoundary"] ''
      fonts_dir=${config.home.homeDirectory}/.local/share/fonts

      rm --recursive --force $fonts_dir
      mkdir --parents $fonts_dir
      cp ${pkgs.corefonts}/share/fonts/truetype/* $fonts_dir/
      cp ${pkgs.vista-fonts}/share/fonts/truetype/* $fonts_dir/
      chmod 755 $fonts_dir
      chmod 644 $fonts_dir/*
    '';
  };
}
