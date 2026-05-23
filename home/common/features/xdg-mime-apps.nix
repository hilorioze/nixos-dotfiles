{
  xdg = {
    mimeApps.enable = true;

    configFile."mimeapps.list".force = true; # required to avoid backup file clash (see https://github.com/nix-community/home-manager/issues/1213)
  };
}
