{
  programs.plasma = {
    krunner.shortcuts.launch = [];

    configFile.kdeglobals."KDE Action Restrictions".run_command = false; # fully disable KRunner: it checks `run_command` before starting (https://invent.kde.org/plasma/plasma-workspace/-/blob/3b9472c3a4ca7e63ad94557bfd2d2accdecf38a1/krunner/main.cpp#L94-96)
  };
}
