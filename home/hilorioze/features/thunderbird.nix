{
  imports = [../../common/features/thunderbird.nix];

  programs = {
    thunderbird.profiles.default.isDefault = true; # lol, why is it not like in firefox?: "true if profile ID is 0"

    plasma.configFile.emaildefaults.PROFILE_Default.EmailClient = "thunderbird.desktop"; # resolve plasma's `preferred://mailer` to thunderbird
  };

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/rss+xml" = "thunderbird.desktop";
    "application/x-extension-rss" = "thunderbird.desktop";
    "message/rfc822" = "thunderbird.desktop";
    "x-scheme-handler/feed" = "thunderbird.desktop";
    "x-scheme-handler/mailto" = "thunderbird.desktop";
    "x-scheme-handler/news" = "thunderbird.desktop";
    "x-scheme-handler/nntp" = "thunderbird.desktop";
    "x-scheme-handler/snews" = "thunderbird.desktop";
    # keep-sorted end
  };
}
