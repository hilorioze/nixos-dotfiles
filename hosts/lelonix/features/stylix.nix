{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    ../../common/features/stylix.nix
    # keep-sorted end
  ];

  stylix = {
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    image = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/DarkestHour/contents/images/2560x1600.jpg";

    cursor = {
      package = pkgs.catppuccin-cursors.macchiatoBlue;
      name = "catppuccin-macchiato-blue-cursors";
      size = 24;
    };
  };
}
