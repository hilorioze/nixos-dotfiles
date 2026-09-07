{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  users = {
    groups.deployer = {};

    users.deployer = {
      isSystemUser = true;

      createHome = true;
      home = "/var/lib/deployer";

      group = config.users.groups.deployer.name;

      shell = pkgs.bash; # nix copy over ssh-ng requires a real shell

      openssh.authorizedKeys.keys = [
        # keep-sorted start
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGuhtLQydHgRNOPGqel/FI2vQ9JtgHN9afnoi2dMnw3EAAAABHNzaDo= hilorioze@hilorioze.com" # required for deploys from local machines
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIlG1hkJk8vgKjLRHmYF9vVtDF1H7Pz9WuhA/fEwn3Mz deployer@nixos-dotfiles"
        # keep-sorted end
      ];
    };
  };

  security.sudo.extraRules = [
    {
      users = ["deployer"];

      commands = [
        # keep-sorted start block=yes newline_separated=yes
        {
          # sudo doesn't resolve symlinks when matching commands (https://github.com/sudo-project/sudo/issues/333)
          command = "/run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*"; # magic rollback confirmation

          options = ["NOPASSWD"];
        }

        {
          command = "/nix/store/*/activate-rs"; # deploy-rs activation helper

          options = [
            # keep-sorted start
            "NOPASSWD"
            "SETENV"
            # keep-sorted end
          ];
        }
        # keep-sorted end
      ];
    }
  ];
}
