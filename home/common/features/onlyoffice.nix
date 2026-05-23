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
      rm -rf ${config.home.homeDirectory}/.local/share/fonts
      mkdir -p ${config.home.homeDirectory}/.local/share/fonts
      cp ${pkgs.corefonts}/share/fonts/truetype/* ${config.home.homeDirectory}/.local/share/fonts/
      cp ${pkgs.vista-fonts}/share/fonts/truetype/* ${config.home.homeDirectory}/.local/share/fonts/
      chmod 755 ${config.home.homeDirectory}/.local/share/fonts
      chmod 644 ${config.home.homeDirectory}/.local/share/fonts/*
    '';
  };
}
