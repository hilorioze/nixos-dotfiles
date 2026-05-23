{pkgs, ...}: {
  home.packages = [
    (pkgs.kdePackages.spectacle.override {
      tesseractLanguages = [
        # keep-sorted start
        "eng"
        "rus"
        "ukr"
        # keep-sorted end
      ];
    })
  ];

  programs.plasma.configFile.spectaclerc = {
    General = {
      autoSaveImage = true;
      clipboardGroup = "PostScreenshotCopyImage";
      closeAfterOcr = true;
      ocrLanguages = "eng,rus,ukr";
      printKeyRunningAction = "FocusWindow";
    };

    GuiConfig = {
      captureMode = "RectangularRegion";
      includePointer = true;
      quitAfterSaveCopyExport = true;
    };
  };
}
