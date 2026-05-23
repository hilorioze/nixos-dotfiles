{
  imports = [../../common/features/openssh.nix];

  sops.secrets."services/openssh/host-keys/ed25519".sopsFile = ../secrets.yaml;

  services.openssh.settings.X11Forwarding = true;
}
