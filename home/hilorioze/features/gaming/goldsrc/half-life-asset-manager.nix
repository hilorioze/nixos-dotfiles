{pkgs, ...}: {
  home.packages = [pkgs.half-life-asset-manager];

  xdg.mimeApps.defaultApplications."application/x-goldsrc-mdl" = "hlam.desktop";
}
