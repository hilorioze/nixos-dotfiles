{
  imports = [
    # keep-sorted start
    ../../common/features/imhex.nix
    # keep-sorted end
  ];

  xdg.mimeApps.defaultApplications."application/vnd.imhex.proj" = "imhex.desktop";
}
