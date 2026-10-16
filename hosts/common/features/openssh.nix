{config, ...}: {
  sops.secrets."services/openssh/host-keys/ed25519".restartUnits = ["sshd.service"];

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
      # disable password authentication
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
