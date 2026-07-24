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

      cex.hilorioze.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFgvannOBsGfTS9JC3hTXRDOmZ47kp6WLfTm6puN/IB
      fakesynology.hilorioze.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL48Td3OYp1cNPORvthU7HCERDli4Zfhsuh2NvnvSB8H
      ${mkKnownHostLine outputs.nixosConfigurations.fakesynology-nixos ../../../hosts/fakesynology-nixos/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.de0 ../../../hosts/de0/ssh_host_ed25519_key.pub}
      ${mkKnownHostLine outputs.nixosConfigurations.hel0 ../../../hosts/hel0/ssh_host_ed25519_key.pub}

      node0.rayttage.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXciAYeEmJZU2PwXBXamfoa/BGDJhry9elTZWOaEsNl
    '';
  };

  programs.ssh.settings = let
    mkSshHost = hostName: settings: {
      "${hostName}" =
        {
          ForwardAgent = true; # for git
        }
        // settings;
    };

    mkNixosHost = name: mkSshHost outputs.nixosConfigurations.${name}.config.networking.fqdn {};

    mkSynologyHost = name: mkSshHost "${name}.hilorioze.com" {User = name;};
  in
    lib.mkMerge [
      {
        "*" = {
          ServerAliveInterval = 25; # keep NAT entries alive during inactivity

          XAuthLocation = lib.getExe pkgs.xauth; # required for X11 forwarding (`ssh -Y`)
        };
      }

      (mkSynologyHost "cex")
      (mkSynologyHost "fakesynology")
      (mkNixosHost "fakesynology-nixos")
      (mkNixosHost "de0")
      (mkNixosHost "hel0")
      (mkNixosHost "hilonix")
      (mkNixosHost "lelonix")
      (mkNixosHost "zikkkix")

      (mkSshHost "node0.rayttage.net" {})
    ];
}
