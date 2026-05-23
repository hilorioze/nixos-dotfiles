{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  stylix = {
    image = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/DarkestHour/contents/images/2560x1440.jpg";

    cursor = {
      package = pkgs.catppuccin-cursors.macchiatoBlue;
      name = "catppuccin-macchiato-blue-cursors";
      size = 24;
    };

    targets.qt.platform = "kde"; # https://github.com/nix-community/stylix/issues/1092
  };
}
