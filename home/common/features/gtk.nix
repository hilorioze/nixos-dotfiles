{pkgs, ...}: let
  gtk-decoration-layout = "icon:minimize,maximize,close";
in {
  # restore `gsettings` schemas missing from the `firefox`/`thunderbird` wrappers (https://github.com/NixOS/nixpkgs/issues/546204)
  xdg.systemDirs.data = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  ];

  gtk = {
    enable = true;

    gtk2.force = true; # workaround for https://github.com/nix-community/home-manager/issues/6188

    gtk3.extraConfig.gtk-decoration-layout = gtk-decoration-layout;
    gtk4.extraConfig.gtk-decoration-layout = gtk-decoration-layout;
  };
}
