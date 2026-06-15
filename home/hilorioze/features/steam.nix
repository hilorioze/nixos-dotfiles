{
  # keep-sorted start
  config,
  lib,
  osConfig,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/steam.nix];

  programs.steam.config = {
    apps = {
      # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=(?s)\bid\s*=\s*(\d+)
      Counter-Strike = {
        id = 10;

        compatTool = "Steam-Play-None"; # fonts missing on steam runtime for some reason, force native runtime

        launchOptions = {
          env = {
            LD_LIBRARY_PATH = "/home/hilorioze/.local/share/Steam/ubuntu12_32:$LD_LIBRARY_PATH";

            LD_PRELOAD = "${pkgs.pkgsi686Linux.SDL2}/lib/libSDL2-2.0.so.0:${pkgs.pkgsi686Linux.cstrike-mod}/lib/libcstrike_mod.so:$LD_PRELOAD";
          };

          wrappers = [
            osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
            (lib.getExe pkgs.gamemode)
            (lib.getExe pkgs.mangohud)
          ];

          args = [
            # keep-sorted start
            "-console"
            "-dev"
            # keep-sorted end
          ];
        };
      };

      Factorio = {
        id = 427520;

        launchOptions.wrappers = [
          osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
          (lib.getExe pkgs.gamemode)
          (lib.getExe pkgs.mangohud)
        ];
      };

      "s&box" = {
        id = 590830;

        compatTool = config.programs.steam.config.defaultCompatTool; # https://github.com/Facepunch/sbox-issues/issues/9759

        launchOptions.wrappers = [
          osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
          (lib.getExe pkgs.gamemode)
          (lib.getExe pkgs.mangohud)
        ];
      };

      Deadlock = {
        id = 1422450;

        compatTool = config.programs.steam.config.defaultCompatTool; # not available natively yet; forces proton_experimental for some reason, so set our own

        launchOptions.wrappers = [
          osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
          (lib.getExe pkgs.gamemode)
          (lib.getExe pkgs.mangohud)
        ];
      };

      "ARC Raiders" = {
        id = 1808500;

        launchOptions.wrappers = [
          osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
          (lib.getExe pkgs.gamemode)
          (lib.getExe pkgs.mangohud)
        ];
      };

      "Counter-Strike:Global Offensive" = {
        id = 4465480;

        launchOptions.wrappers = [
          osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
          (lib.getExe pkgs.gamemode)
          (lib.getExe pkgs.mangohud)
        ];
      };
      # keep-sorted end
    };

    nonSteamApps."Beat Saber 1.40.8" = let
        bsManagerBasePath = "/mnt/vol/Games/BSManager";

        instance = "1.40.8";

        instancePath = "${bsManagerBasePath}/BSInstances/${instance}";
      in {
        target = "${pkgs.proton-ge-bin.steamcompattool}/proton";

        startIn = instancePath;

        launchOptions = {
          env = let
            beatSaberAppId = 620980;
          in {
            # keep-sorted start
            STEAM_COMPAT_APP_ID = beatSaberAppId;
            STEAM_COMPAT_CLIENT_INSTALL_PATH = "/home/hilorioze/.steam/steam";
            STEAM_COMPAT_DATA_PATH = "${bsManagerBasePath}/SharedContent/compatdata";
            STEAM_COMPAT_INSTALL_PATH = instancePath;
            SteamAppId = beatSaberAppId;
            SteamEnv = true;
            SteamGameId = beatSaberAppId;
            SteamOverlayGameId = beatSaberAppId;
            WINEDLLOVERRIDES = "winhttp=n,b";
            # keep-sorted end
          };

          wrappers = [
            osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
            (lib.getExe pkgs.gamemode)
            (lib.getExe pkgs.mangohud)
            (lib.getExe pkgs.steam-run)
          ];

          args = [
            "run"

            "${instancePath}/Beat Saber.exe"

            "--no-yeet"
          ];
        };

        inVrLibrary = true;
    };
  };
}
