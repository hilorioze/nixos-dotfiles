{
  programs.firefox = {
    enable = true;

    profiles.default.settings = {
      # nix manages extension versions
      "extensions.update.enabled" = false;
      "extensions.update.autoUpdateDefault" = false;

      # fixes extensions being disabled right after a fresh install
      "extensions.autoDisableScopes" = 0;

      # use native file picker instead of GTK file picker
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    };
  };
}
