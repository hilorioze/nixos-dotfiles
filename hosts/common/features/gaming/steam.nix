{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.steam = {
    enable = true;

    package = pkgs.steam.override {
      extraEnv = let
        # offload to the nvidia gpu while it's bound to its driver, not passed through to a vm
        gpuSelect = pkgs.writeShellScript "steam-gpu-select" ''
          unset VK_DRIVER_FILES # lift the client's restriction below

          shopt -s nullglob
          gpus=(/proc/driver/nvidia/gpus/*)

          offload=()
          if ((''${#gpus[@]})); then
            offload=(${config.hardware.nvidia.prime.offload.offloadCmdMainProgram})
          fi

          exec "''${offload[@]}" "$@"
        '';
      in
        {
          LD_PRELOAD = "${pkgs.pkgsi686Linux.steam-voicechat-fix}/lib/libsteam_voicechat_fix.so";

          # every game launches through this, so they need no launch options for these wrappers; opengl games don't pick the gpu themselves
          STEAM_GAME_LAUNCH_SHELL = pkgs.writeShellScript "steam-game-launch-shell" ''
            exec ${gpuSelect} ${lib.getExe pkgs.gamemode} ${lib.getExe pkgs.mangohud} /bin/sh -c "$1"
          '';

          # precompile steam's shader cache for the gpu the games run on
          FOSSILIZE_REPLAY_WRAPPER = pkgs.writeShellScript "steam-fossilize-replay-wrapper" ''
            unset FOSSILIZE_REPLAY_WRAPPER # `fossilize_replay` hands over to the wrapper again while it's set

            exec ${gpuSelect} "$FOSSILIZE_REPLAY_WRAPPER_ORIGINAL_APP" "$@"
          '';
        }
        // lib.optionalAttrs config.hardware.nvidia.powerManagement.finegrained {
          # restrict the client and steamwebhelper to the display gpu, so they don't wake the nvidia gpu or hold it while it's passed through to a vm
          VK_DRIVER_FILES = let
            driver =
              if config.hardware.nvidia.prime.amdgpuBusId != ""
              then "radeon"
              else "intel";
          in "${pkgs.mesa}/share/vulkan/icd.d/${driver}_icd.x86_64.json:${pkgs.pkgsi686Linux.mesa}/share/vulkan/icd.d/${driver}_icd.i686.json";
        };
    };

    remotePlay.openFirewall = true;

    localNetworkGameTransfers.openFirewall = true;

    extraCompatPackages = with pkgs; [
      # keep-sorted start
      proton-ge-bin
      steam-play-none
      steamtinkerlaunch
      # keep-sorted end
    ];
  };
}
