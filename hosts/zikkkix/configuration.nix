{pkgs, ...}: {
  programs = {
    # keep-sorted start block=yes newline_separated=true
    coolercontrol.enable = true;

    steam = {
      enable = true;

      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      extraCompatPackages = [pkgs.proton-ge-bin];
    };
    # keep-sorted end
  };

  # installation through `environment.systemPackages` is required for polkit privilege escalation (home-manager install won't work)
  environment.systemPackages = [pkgs.kdiskmark];

  boot.loader.systemd-boot.configurationLimit = 2;

  time.timeZone = "Europe/Dublin";

  i18n = {
    defaultLocale = "en_IE.UTF-8";

    extraLocaleSettings.LANGUAGE = "en_IE:en_GB:en";
  };

  # Make RAPL energy files readable for MangoHud CPU power display
  systemd.tmpfiles.rules = ["z /sys/class/powercap/intel-rapl*/energy_uj 0444 root root -"];
}
