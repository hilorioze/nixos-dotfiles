{osConfig, ...}: {
  stylix = {
    inherit (osConfig.stylix) image cursor;

    targets.qt.platform = "kde"; # https://github.com/nix-community/stylix/issues/1092
  };
}
