{pkgs, ...}: {
  programs.steam = {
    enable = true;

    package = pkgs.steam.override {
      extraEnv.LD_PRELOAD = "${pkgs.pkgsi686Linux.steam-voicechat-fix}/lib/libsteam_voicechat_fix.so";
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
