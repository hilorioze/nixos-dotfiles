{pkgs, ...}: let
  gtk-decoration-layout = "icon:minimize,maximize,close";
in {
  # restore gsettings schemas missing from the firefox/thunderbird wrappers (https://github.com/NixOS/nixpkgs/issues/546204)
  xdg.systemDirs.data = map (package: "${package}/share/gsettings-schemas/${package.name}") (with pkgs; [
    # keep-sorted start
    gsettings-desktop-schemas
    gtk3
    # keep-sorted end
  ]);

  gtk = {
    enable = true;

    gtk2.force = true; # workaround for https://github.com/nix-community/home-manager/issues/6188

    gtk3.extraConfig.gtk-decoration-layout = gtk-decoration-layout;
    gtk4.extraConfig.gtk-decoration-layout = gtk-decoration-layout;
  };

  # apps like telegram read the layout through the gtk portal; stylix disables kde's gtkconfig, which would sync it
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = gtk-decoration-layout;
}
