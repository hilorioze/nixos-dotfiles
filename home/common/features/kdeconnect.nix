{lib, ...}: {
  services.kdeconnect.enable = true;

  # drop the profile-only `PATH` home-manager 26.05 sets (master no longer does): it hides the `fusermount` wrapper, so kdeconnect leaves a dead sshfs mount behind and every later mount fails on it
  systemd.user.services.kdeconnect.Service.Environment = lib.mkForce [];
}
