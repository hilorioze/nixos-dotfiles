{
  imports = [../../common/features/openssh.nix];

  services.openssh.settings.X11Forwarding = true;
}
