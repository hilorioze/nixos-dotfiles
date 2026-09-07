{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets = {
    # keep-sorted start
    "credentials/ssh/agent/private-key" = {};
    "credentials/ssh/fido2/private-key".path = "${config.home.homeDirectory}/.ssh/id_ed25519_sk";
    # keep-sorted end
  };

  services.ssh-agent.enable = true;

  # select `ssh`'s direct signing path when neither `DISPLAY` (X11) nor `WAYLAND_DISPLAY` (Wayland) is set because `ssh-agent` cannot read the FIDO2 PIN from `ssh`'s TTY
  programs.ssh.extraConfig = ''
    Match exec "test -z \"$DISPLAY$WAYLAND_DISPLAY\""
      IdentityAgent none
  '';

  systemd.user.services = {
    ssh-agent.Service.Environment = "SSH_ASKPASS=${lib.getExe pkgs.kdePackages.ksshaskpass}"; # configure `ssh-agent` to use `ksshaskpass` for FIDO2 PIN prompts in graphical sessions instead of OpenSSH's default `ssh-askpass`

    ssh-agent-load-keys = {
      Install.WantedBy = ["default.target"];

      Unit = {
        Wants = [
          # keep-sorted start
          "sops-nix.service"
          "ssh-agent.service"
          # keep-sorted end
        ];

        After = [
          # keep-sorted start
          "sops-nix.service"
          "ssh-agent.service"
          # keep-sorted end
        ];

        PartOf = ["ssh-agent.service"];
      };

      Service = {
        Type = "oneshot";

        Environment = "SSH_AUTH_SOCK=%t/${config.services.ssh-agent.socket}";
        ExecStart = [
          # keep-sorted start
          "${lib.getExe' pkgs.openssh "ssh-add"} ${config.sops.secrets."credentials/ssh/agent/private-key".path}"
          "${lib.getExe' pkgs.openssh "ssh-add"} ${config.sops.secrets."credentials/ssh/fido2/private-key".path}" # preload the FIDO2 key into `ssh-agent` because `AddKeysToAgent` only adds a file-loaded key after selecting the direct signing path and does not use the agent for the current signature
          # keep-sorted end
        ];

        RemainAfterExit = true;
      };
    };
  };
}
