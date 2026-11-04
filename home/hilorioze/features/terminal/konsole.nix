{
  imports = [../../../common/features/terminal/konsole.nix];

  programs.konsole.profiles.default.extraConfig.General = {
    TerminalColumns = 201;
    TerminalRows = 52;

    StartInCurrentSessionDir = false; # keep cwd inheritance out of new tabs
  };
}
