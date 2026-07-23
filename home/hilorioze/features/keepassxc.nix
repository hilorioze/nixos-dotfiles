{
  imports = [../../common/features/keepassxc.nix];

  programs.keepassxc = {
    autostart = true;

    settings = {
      GUI = {
        ApplicationTheme = "classic";

        ShowTrayIcon = true;

        MinimizeOnClose = true;
      };

      Browser = {
        Enabled = true;

        AlwaysAllowAccess = true;
        AlwaysAllowUpdate = true;
        HttpAuthPermission = true;

        SearchInAllDatabases = true;

        AllowLocalhostWithPasskeys = true;
      };

      FdoSecrets = {
        Enabled = true;

        ConfirmAccessItem = false; # disable access prompts
      };

      Security = {
        # keep the database unlocked no matter what
        LockDatabaseIdle = false;
        LockDatabaseScreenLock = false;
      };
    };
  };
}
