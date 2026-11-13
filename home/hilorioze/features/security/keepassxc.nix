{
  imports = [../../../common/features/security/keepassxc.nix];

  programs.keepassxc.settings = {
    GUI = {
      ApplicationTheme = "classic";

      ShowTrayIcon = true;

      MinimizeOnClose = true;
    };

    Browser = {
      Enabled = true;

      UpdateBinaryPath = false; # home-manager manages the native messaging manifests

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
}
