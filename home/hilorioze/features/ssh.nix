{
  # keep-sorted start
  lib,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/ssh.nix];

  home.file.".ssh/known_hosts" = {
    force = true;

    text = let
      mkKnownHostLine = nixosConfiguration: path: "${nixosConfiguration.config.networking.fqdn} ${builtins.readFile path}";
    in ''
      ${mkKnownHostLine outputs.nixosConfigurations.lelonix ../../../hosts/lelonix/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.hilonix ../../../hosts/hilonix/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.zikkkix ../../../hosts/zikkkix/ssh_host_ed25519_key.pub}

      fakesynology.hilorioze.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL48Td3OYp1cNPORvthU7HCERDli4Zfhsuh2NvnvSB8H
      ${mkKnownHostLine outputs.nixosConfigurations.fakesynology-nixos ../../../hosts/fakesynology-nixos/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.de0 ../../../hosts/de0/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.hel0 ../../../hosts/hel0/ssh_host_ed25519_key.pub}

      node0.rayttage.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXciAYeEmJZU2PwXBXamfoa/BGDJhry9elTZWOaEsNl
    '';
  };

  programs.ssh.matchBlocks = {
    "*" = {
      serverAliveInterval = 25; # keep NAT entries alive during inactivity

      extraOptions.XAuthLocation = lib.getExe pkgs.xauth; # required for X11 forwarding (`ssh -Y`)
    };

    "fakesynology.hilorioze.com" = {
      user = "fakesynology";

      forwardAgent = true; # for git
    };
    "${outputs.nixosConfigurations.fakesynology-nixos.config.networking.fqdn}".forwardAgent = true; # for git
    "${outputs.nixosConfigurations.lelonix.config.networking.fqdn}".forwardAgent = true; # for git
    "${outputs.nixosConfigurations.hilonix.config.networking.fqdn}".forwardAgent = true; # for git
    "${outputs.nixosConfigurations.zikkkix.config.networking.fqdn}".forwardAgent = true; # for git
    "${outputs.nixosConfigurations.de0.config.networking.fqdn}".forwardAgent = true; # for git
    "${outputs.nixosConfigurations.hel0.config.networking.fqdn}".forwardAgent = true; # for git

    "node0.rayttage.net".forwardAgent = true; # for git
  };
}
