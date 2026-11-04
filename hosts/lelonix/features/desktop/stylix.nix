{pkgs, ...}: {
  imports = [../../../common/features/desktop/stylix.nix];

  stylix.image = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/DarkestHour/contents/images/2560x1600.jpg";
}
