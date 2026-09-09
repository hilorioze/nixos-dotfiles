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
    "credentials/ssh/fido2/private-key" = {};
    # keep-sorted end
  };

  # use direct FIDO2 signing in TTY sessions so `ssh` can read the PIN from the TTY
  programs.ssh.extraConfig = ''
    Match exec "test -z \"$DISPLAY$WAYLAND_DISPLAY\""
      IdentityAgent none
      IdentityFile ${config.sops.secrets."credentials/ssh/fido2/private-key".path}
  '';

  services.ssh-agent.enable = true;

  systemd.user.services = {
    ssh-agent = {
      Install.WantedBy = lib.mkForce ["graphical-session.target"]; # wait for `$DISPLAY` or `$WAYLAND_DISPLAY` so `$SSH_ASKPASS` can be used

      Unit = {
        After = ["graphical-session.target"];

        PartOf = ["graphical-session.target"];
      };

      Service.Environment = "SSH_ASKPASS=${lib.getExe pkgs.kdePackages.ksshaskpass}"; # use `ksshaskpass` for graphical FIDO2 PIN prompts
    };

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
          "${lib.getExe' pkgs.openssh "ssh-add"} ${config.sops.secrets."credentials/ssh/fido2/private-key".path}"
          # keep-sorted end
        ];

        RemainAfterExit = true;
      };
    };
  };
}
