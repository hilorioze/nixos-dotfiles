{pkgs, ...}: {
  imports = [../../common/features/dolphin.nix];

  home.packages = [pkgs.kdePackages.kio-zeroconf];

  programs.plasma = {
    # dolphin global fallback view property used for directories without local settings when GlobalViewProps=false
    dataFile."dolphin/view_properties/global/.directory".Settings.HiddenFilesShown = true;

    configFile = {
      baloofileinformationrc.Show = {
        # keep-sorted start
        "kfileitem#accessed" = false;
        "kfileitem#comment" = false;
        "kfileitem#created" = true;
        "kfileitem#group" = true;
        "kfileitem#modified" = true;
        "kfileitem#owner" = true;
        "kfileitem#permissions" = true;
        "kfileitem#size" = true;
        "kfileitem#type" = true;
        channels = true;
        comment = false;
        contentCreated = true;
        contentSize = true;
        created = true;
        depends = true;
        embeddedRating = true;
        fileName = true;
        fileSize = true;
        height = true;
        lastModified = true;
        lyrics = true;
        mimeType = true;
        photoGpsLatitude = true;
        photoGpsLongitude = true;
        photoMeteringMode = true;
        photoPixelXDimension = true;
        photoPixelYDimension = true;
        photoSaturation = true;
        photoSharpness = true;
        photoWhiteBalance = true;
        rating = false;
        replayGainAlbumGain = true;
        replayGainAlbumPeak = true;
        replayGainTrackGain = true;
        replayGainTrackPeak = true;
        tags = false;
        url = true;
        userComment = false;
        width = true;
        # keep-sorted end
      };

      dolphinrc.General = {
        # keep-sorted start
        BrowseThroughArchives = true;
        DynamicView = true; # automatically switches to icons view for folders containing mostly images and videos
        FilterBar = true;
        GlobalViewProps = false; # use individual view settings for each directory
        OpenExternallyCalledFolderInNewTab = true;
        ShowFullPath = true;
        ShowFullPathInTitlebar = true;
        ShowToolTips = true;
        TerminalPanelVisible = true;
        # keep-sorted end
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/x-gnome-saved-search" = "org.kde.dolphin.desktop";
    "inode/directory" = "org.kde.dolphin.desktop";
    # "x-scheme-handler/file" = "org.kde.dolphin.desktop"; # routes ALL file:// urls through dolphin first, breaking direct app launches (e.g. PDF -> Dolphin -> Okular instead of PDF -> Okular)
    # keep-sorted end
  };
}
