{pkgs, ...}: {
  programs.steam.package = pkgs.steam.override {
    extraEnv = {
      LD_PRELOAD = "${pkgs.pkgsi686Linux.steam-voicechat-fix}/lib/libsteam_voicechat_fix.so";

      # restrict the client and steamwebhelper to use the host gpu
      VK_DRIVER_FILES = "${pkgs.mesa}/share/vulkan/icd.d/radeon_icd.x86_64.json:${pkgs.pkgsi686Linux.mesa}/share/vulkan/icd.d/radeon_icd.i686.json";

      # lift the restriction for games
      STEAM_GAME_LAUNCH_SHELL = pkgs.writeShellScript "steam-game-launch-shell" ''
        unset VK_DRIVER_FILES

        exec /bin/sh -c "$1"
      '';
    };
  };
}
