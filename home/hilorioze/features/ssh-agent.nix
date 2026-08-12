{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  services.ssh-agent.enable = true;

  systemd.user.services.ssh-agent.Service.Environment = "SSH_ASKPASS=${lib.getExe pkgs.kdePackages.ksshaskpass}";
}
