{pkgs, ...}: {
  programs.steam = {
    enable = true;
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
