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

  programs.steam.config = let
    wrappers = [
      osConfig.hardware.nvidia.prime.offload.offloadCmdMainProgram
      (lib.getExe pkgs.gamemode)
      (lib.getExe pkgs.mangohud)
    ];
  in {
    apps = {
      # keep-sorted start block=yes newline_separated=yes numeric=yes
      "10" = {
        name = "Counter-Strike";

        # skip pressure-vessel, which overwrites `LD_LIBRARY_PATH` after launch options are applied
        compatTool = "Steam-Play-None";

        env = {
          LD_LIBRARY_PATH = "${lib.makeLibraryPath (with pkgs.pkgsi686Linux; [
            # keep-sorted start
            freetype # steam-runtime's freetype cannot load normal truetype fonts
            libX11 # use the same `libX11` as mangohud to avoid a crash in `XCreateGC`
            openal # steam-runtime's openal-soft 1.16 hangs the exit once its stream loses the sink, e.g. after bluetooth headphones reconnect
            pipewire # openal's runpath loses to steam-runtime's libpipewire 0.3.27 on `LD_LIBRARY_PATH`
            stdenv.cc.cc.lib # steam-runtime's `libgcc_s.so.1` lacks `GCC_7.0.0`, required by mangohud
            # keep-sorted end
          ])}:$LD_LIBRARY_PATH";

          LD_PRELOAD = "${pkgs.pkgsi686Linux.cstrike-mod}/lib/libcstrike_mod.so:$LD_PRELOAD";

          # the engine plays 22050 hz, and the default resampler of pipewire-pulse cuts it from 9.6 khz instead of 11 khz, which sounds muffled
          PULSE_PROP = "resample.quality=14";
        };

        preHook = ''
          # prepend game directory to `LD_LIBRARY_PATH` at runtime so `Sys_LoadModule` can resolve `libcef.so` (dep of `chromehtml.so`)
          export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH

          # csldr loads the original client from `client_orig.so` next to itself; a `client.so` without csldr's version string is valve's own, from a fresh install, an update or a file check
          if ! grep --quiet --fixed-strings 'csldr version' cstrike/cl_dlls/client.so; then
            mv --force cstrike/cl_dlls/client.so cstrike/cl_dlls/client_orig.so
          fi

          # not a symlink: the engine's filesystem doesn't find a symlinked `client.so` and fails with "could not link client.dll function Initialize"
          cp --remove-destination ${pkgs.pkgsi686Linux.csldr}/lib/client.so cstrike/cl_dlls/client.so
        '';

        inherit wrappers;

        args = [
          # keep-sorted start
          "-console"
          "-dev"
          # keep-sorted end
        ];
      };

      "570" = {
        name = "Dota 2";

        inherit wrappers;
      };

      "427520" = {
        name = "Factorio";

        inherit wrappers;
      };

      "590830" = {
        name = "s&box";

        compatTool = config.programs.steam.config.defaultCompatTool; # https://github.com/Facepunch/sbox-issues/issues/9759

        inherit wrappers;
      };

      "1422450" = {
        name = "Deadlock";

        compatTool = config.programs.steam.config.defaultCompatTool; # not available natively yet; forces `proton_experimental` for some reason, so set our own

        inherit wrappers;
      };

      "1808500" = {
        name = "ARC Raiders";

        inherit wrappers;
      };

      "2406770" = {
        name = "Bodycam";

        inherit wrappers;
      };

      "4465480" = {
        name = "Counter-Strike:Global Offensive";

        inherit wrappers;
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

      env = let
        appId = 620980;
      in {
        SteamEnv = true;

        STEAM_COMPAT_APP_ID = appId;
        SteamAppId = appId;
        SteamGameId = appId;
        SteamOverlayGameId = appId;

        STEAM_COMPAT_CLIENT_INSTALL_PATH = "/home/hilorioze/.steam/steam";
        STEAM_COMPAT_DATA_PATH = "${bsManagerBasePath}/SharedContent/compatdata";
        STEAM_COMPAT_INSTALL_PATH = instancePath;

        WINEDLLOVERRIDES = "winhttp=n,b";
      };

      wrappers = wrappers ++ [(lib.getExe pkgs.steam-run)];

      args = [
        "run"

        "${instancePath}/Beat Saber.exe"

        "--no-yeet"
      ];

      inVrLibrary = true;
    };
  };
}
