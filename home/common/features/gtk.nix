let
  gtk-decoration-layout = "icon:minimize,maximize,close";
in {
  gtk = {
    enable = true;

    gtk2.force = true; # workaround for https://github.com/nix-community/home-manager/issues/6188

    gtk3.extraConfig.gtk-decoration-layout = gtk-decoration-layout;
    gtk4.extraConfig.gtk-decoration-layout = gtk-decoration-layout;
  };
}
