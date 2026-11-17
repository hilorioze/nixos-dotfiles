{config, ...}: {
  sops.secrets."services/openssh/host-keys/ed25519".restartUnits = ["sshd.service"];

  services.openssh = {
    enable = true;

    ports = [58810]; # 22 belongs to cowrie

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

      DisableForwarding = true; # disable tcp, unix-socket, agent and x11 forwarding
    };
  };
}
