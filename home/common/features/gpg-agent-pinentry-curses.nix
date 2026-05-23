{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  services.gpg-agent.pinentry.package = lib.mkDefault pkgs.pinentry-curses;
}
