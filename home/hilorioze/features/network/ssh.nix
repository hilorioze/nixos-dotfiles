{
  # keep-sorted start
  lib,
  outputs,
  # keep-sorted end
  ...
}: {
  home.file.".ssh/known_hosts" = {
    force = true;

    text = let
      mkKnownHostLine = nixosConfiguration: path: "${nixosConfiguration.config.networking.fqdn} ${builtins.readFile path}";
    in ''
      github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl

      ${mkKnownHostLine outputs.nixosConfigurations.lelonix ../../../../hosts/lelonix/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.hilonix ../../../../hosts/hilonix/ssh_host_ed25519_key.pub}

      cex.hilorioze.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFgvannOBsGfTS9JC3hTXRDOmZ47kp6WLfTm6puN/IB
      ${mkKnownHostLine outputs.nixosConfigurations.cex-nixos ../../../../hosts/cex-nixos/ssh_host_ed25519_key.pub}
      fakesynology.hilorioze.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL48Td3OYp1cNPORvthU7HCERDli4Zfhsuh2NvnvSB8H
      ${mkKnownHostLine outputs.nixosConfigurations.fakesynology-nixos ../../../../hosts/fakesynology-nixos/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.de0 ../../../../hosts/de0/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.hel0 ../../../../hosts/hel0/ssh_host_ed25519_key.pub}
      [${outputs.deploy.nodes.honeypot.hostname}]:${toString (builtins.head outputs.nixosConfigurations.honeypot.config.services.openssh.ports)} ${builtins.readFile ../../../../hosts/honeypot/ssh_host_ed25519_key.pub}

      node0.rayttage.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXciAYeEmJZU2PwXBXamfoa/BGDJhry9elTZWOaEsNl
    '';
  };

  programs.ssh = {
    enable = true;

    enableDefaultConfig = false; # its default is already deprecated and home-manager recommends setting it to `false`

    settings = let
      mkSynologyHost = name: {"${name}.hilorioze.com".User = name;};
    in
      lib.mkMerge [
        {
          "*" = {
            HostKeyAlgorithms = "ssh-ed25519";

            ServerAliveInterval = 25; # keep nat entries alive during inactivity
          };
        }

        {
          # let vscode's sync push over its pull's connection, so the fido2 key asks for one touch; a minute also outlasts pull's rebase re-signing commits with a pin and touch each
          "github.com" = {
            ControlMaster = "auto";
            ControlPersist = "1m";
            ControlPath = "\${XDG_RUNTIME_DIR}/ssh-github-%C";
          };
        }

        {
          honeypot = {
            HostName = outputs.deploy.nodes.honeypot.hostname;
            Port = builtins.head outputs.nixosConfigurations.honeypot.config.services.openssh.ports;

            User = outputs.nixosConfigurations.honeypot.config.users.users.root.name;
          };
        }

        # keep-sorted start
        (mkSynologyHost "cex")
        (mkSynologyHost "fakesynology")
        # keep-sorted end
      ];
  };
}
