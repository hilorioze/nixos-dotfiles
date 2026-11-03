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

    authorizedKeysInHomedir = false; # use only declarative ssh keys from `users.users.<name>.openssh.authorizedKeys`; ignore user-managed `~/.ssh/authorized_keys`

    settings = {
      PermitRootLogin = "no";

      # disable password authentication
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      DisableForwarding = true; # disable tcp, unix-socket, agent and x11 forwarding by default
    };

    extraConfig = ''
      Match User ${config.users.users.hilorioze.name},${config.users.users.agent.name}
        DisableForwarding no
    '';
  };
}
