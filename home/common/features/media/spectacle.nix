{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  ocrLanguages = [
    # keep-sorted start
    "eng"
    "rus"
    "ukr"
    # keep-sorted end
  ];
in {
  home.packages = [(pkgs.kdePackages.spectacle.override {tesseractLanguages = ocrLanguages;})];

  programs.plasma.configFile.spectaclerc = {
    General = {
      printKeyRunningAction = "FocusWindow";

      autoSaveImage = true;
      clipboardGroup = "PostScreenshotCopyImage";

      ocrLanguages = lib.concatStringsSep "," ocrLanguages;
      closeAfterOcr = true;
    };

    GuiConfig = {
      captureMode = "RectangularRegion";
      includePointer = true;

      quitAfterSaveCopyExport = true;
    };
  };
}
