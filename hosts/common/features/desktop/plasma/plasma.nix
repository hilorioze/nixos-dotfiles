{pkgs, ...}: {
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = [pkgs.kdePackages.discover];

  # a launcher waits until its crash notification closes, which a notification kept in the history never does, and the socket drops new crashes once 16 launchers wait
  systemd.user.services."drkonqi-coredump-launcher@" = {
    overrideStrategy = "asDropin"; # the default strategy sees no upstream unit in drkonqi's `share/systemd/user` and replaces the whole unit

    enableDefaultPath = false; # keep the user manager's `PATH`: the launcher looks up `drkonqi-coredump-gui` there

    serviceConfig.RuntimeMaxSec = "1h"; # the notification's `Details` button works until then
    unitConfig.CollectMode = "inactive-or-failed"; # drop the instances the timeout leaves failed
  };
}
