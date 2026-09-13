{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  sshAskpass = pkgs.writeShellScript "ssh-askpass" ''
    # suppress OpenSSH's initial "confirm user presence" dialog while keeping its askpass process alive until the PIN prompt
    if [[ ''${SSH_ASKPASS_PROMPT-} == none ]]; then
      exec ${lib.getExe' pkgs.coreutils "sleep"} infinity
    fi

    exec ${lib.getExe' pkgs.systemd "systemd-run"} \
      --user \
      --pipe \
      --collect \
      ${lib.getExe pkgs.kdePackages.ksshaskpass} "$@"
  '';
in {
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
    ssh-agent.Service.Environment = [
      "SSH_ASKPASS=${sshAskpass}"

      "SSH_ASKPASS_REQUIRE=force"
    ];

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
