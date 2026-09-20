{
  # keep-sorted start
  appimageTools,
  fetchurl,
  lib,
  # keep-sorted end
}: let
  pname = "quickshare";

  version = "0.6";

  src = fetchurl {
    url = "https://github.com/kidfromjupiter/nearby/releases/download/v${version}/QuickShare-x86_64.AppImage";

    hash = "sha256-jIF/XsyhQwILexUvSyuGEplu9/IxRJCumAcgGzOUbFs=";
  };

  contents = appimageTools.extract {
    inherit pname;

    inherit version;

    inherit src;
  };
in
  appimageTools.wrapType2 {
    inherit pname;

    inherit version;

    inherit src;

    extraPkgs = pkgs:
      with pkgs; [
        bluez
        curl
        zstd
      ];

    extraInstallCommands = ''
      cp --recursive ${contents}/usr/share $out/
    '';

    meta = {
      description = "Share files with nearby devices";
      homepage = "https://github.com/kidfromjupiter/nearby";

      license = lib.licenses.asl20;

      mainProgram = "quickshare";

      platforms = ["x86_64-linux"];
    };
  }
