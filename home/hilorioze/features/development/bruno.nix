{pkgs, ...}: {
  home.packages = [pkgs.bruno];

  xdg.mimeApps.defaultApplications."x-scheme-handler/bruno" = "bruno.desktop";
}
