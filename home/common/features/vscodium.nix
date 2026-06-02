{lib, ...}: {
  programs.vscodium = {
    enable = true;

    mutableExtensionsDir = lib.mkDefault false;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      userSettings."update.showReleaseNotes" = false;
    };
  };
}
