{config, ...}: {
  sops.secrets."services/openssh/host-keys/ed25519" = {};

  services.openssh = {
    enable = true;

    # Use only Ed25519 host keys
    hostKeys = [
      {
        inherit (config.sops.secrets."services/openssh/host-keys/ed25519") path;
        type = "ed25519";
      }
    ];

    settings = {
      # Disable password authentication
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
