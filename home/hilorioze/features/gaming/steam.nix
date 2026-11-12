{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.steam-config-nix.homeModules.default];

  programs.steam.config = {
    enable = true;

    onSteamRunning = "close";

    defaultCompatTool = "GE-Proton";

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
          # load scout's libraries explicitly: `Steam-Play-None` bypasses the runtime, and the 64-bit steam client doesn't provide them; steam's `search-cwd` flag also appends the game directory, where `Sys_LoadModule` resolves `libcef.so` (dep of `chromehtml.so`)
          export LD_LIBRARY_PATH=$("$STEAM_COMPAT_CLIENT_INSTALL_PATH/steamapps/common/SteamLinuxRuntime/steam-runtime/run.sh" --print-steam-runtime-library-paths)

          # csldr loads the original client from `client_orig.so` next to itself; a `client.so` without csldr's version string is valve's own, from a fresh install, an update or a file check
          if ! grep --quiet --fixed-strings 'csldr version' cstrike/cl_dlls/client.so; then
            mv --force cstrike/cl_dlls/client.so cstrike/cl_dlls/client_orig.so
          fi

          # not a symlink: the engine's filesystem doesn't find a symlinked `client.so` and fails with "could not link client.dll function Initialize"
          cp --remove-destination ${pkgs.pkgsi686Linux.csldr}/lib/client.so cstrike/cl_dlls/client.so
        '';

        args = [
          # keep-sorted start
          "-console"
          "-dev"
          # keep-sorted end
        ];
      };

      "1422450" = {
        name = "Deadlock";

        compatTool = config.programs.steam.config.defaultCompatTool; # not available natively yet; forces `proton_experimental` for some reason, so set our own
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

      wrappers = [(lib.getExe pkgs.steam-run)];

      args = [
        "run"

        "${instancePath}/Beat Saber.exe"

        "--no-yeet"
      ];

      inVrLibrary = true;
    };
  };
}
