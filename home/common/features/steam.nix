{inputs, ...}: {
  imports = [inputs.steam-config-nix.homeModules.default];

  programs.steam.config = {
    enable = true;

    onSteamRunning = "close";

    defaultCompatTool = "GE-Proton";
  };
}
