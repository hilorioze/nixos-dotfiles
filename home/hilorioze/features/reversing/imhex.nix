{pkgs, ...}: {
  home.packages = [pkgs.imhex];

  xdg.mimeApps.defaultApplications."application/vnd.imhex.proj" = "imhex.desktop";
}
