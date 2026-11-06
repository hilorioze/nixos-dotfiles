{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  # kwin starts the onscreen keyboard only with an input method set, and the lock screen's keyboard button relies on it
  environment.etc."xdg/kwinrc".text = lib.generators.toINI {} {
    Wayland.InputMethod = "${pkgs.kdePackages.plasma-keyboard}/share/applications/org.kde.plasma.keyboard.desktop";
  };
}
