{config, ...}: {
  sops.secrets."services/openssh/host-keys/ed25519" = {};

  services.openssh = {
    enable = true;

    # use only ed25519 host keys
    hostKeys = [
      {
        type = "ed25519";

        inherit (config.sops.secrets."services/openssh/host-keys/ed25519") path;
      }
    ];

    settings = {
      X11Forwarding = true;

      # Disable password authentication
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
