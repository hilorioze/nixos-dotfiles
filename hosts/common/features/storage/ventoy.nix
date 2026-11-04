{lib, ...}: {
  nixpkgs.config.allowInsecurePredicate = pkg: lib.getName pkg == "ventoy-qt5";
}
