{pkgs, ...}: {
  imports = [../../common/features/stylix.nix];

  stylix = {
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    opacity.popups = 0.5;
  };
}
