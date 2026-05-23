{
  imports = [../../common/features/konsole.nix];

  programs.konsole = {
    defaultProfile = "default";

    profiles.default = {
      font = {
        name = "MesloLGS NF";

        size = 12;
      };

      extraConfig.Scrolling.HistoryMode = 2; # 0 = NoHistory, 1 = FixedSizeHistory, 2 = UnlimitedHistory (https://github.com/KDE/konsole/blob/e30cbe352363ee6a15f979553af2825279193c3e/src/Enumeration.h#L19-L37)
    };
  };
}
