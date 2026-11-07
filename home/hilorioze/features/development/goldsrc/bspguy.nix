{pkgs, ...}: {
  home.packages = [pkgs.bspguy];

  xdg.mimeApps.defaultApplications."application/x-goldsrc-bsp" = "bspguy.desktop";
}
