{
  imports = [../../common/features/bruno.nix];

  xdg.mimeApps.defaultApplications."x-scheme-handler/bruno" = "bruno.desktop";
}
