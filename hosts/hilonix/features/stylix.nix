{pkgs, ...}: {
  imports = [../../common/features/stylix.nix];

  stylix = {
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    image = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/DarkestHour/contents/images/2560x1440.jpg";

    cursor = {
      package = pkgs.catppuccin-cursors.macchiatoBlue;
      name = "catppuccin-macchiato-blue-cursors";
      size = 24;
    };
  };
}
