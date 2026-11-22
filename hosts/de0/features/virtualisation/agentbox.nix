{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets =
      {
        "services/agentbox/github/access-token" = {}; # `agentbox-bootstrap@nixos-dotfiles`, a fine-grained token that reads the contents of every agentbox repository
      }
      // lib.mapAttrs' (name: _machine:
        lib.nameValuePair "services/agentbox/machines/${name}/age-key" {
          restartUnits = ["systemd-nspawn@agentbox-${name}.service"];
        })
      config.virtualisation.agentbox.machines;

    templates."agentbox-bootstrap/nix.conf".content = "access-tokens = github.com=${config.sops.placeholder."services/agentbox/github/access-token"}";
  };

  services.resolved.enable = false; # networkd turns it on, yet the host keeps resolving through openresolv and tailscale

  networking = {
    dhcpcd.denyInterfaces = [
      "agentbox"
      "vb-*" # bridge ports: nspawn's host side of each agentbox's veth
    ];

    nat = {
      enable = true;

      internalInterfaces = ["agentbox"];

      externalInterface = "enp0s3";
    };

    # keep agentboxes off the host's private networks, the tailnet, cloud metadata and each other; only the internet stays reachable
    # only drops: a drop is final for the packet, while an accept would end just this chain and leave the verdict to podman's and tailscale's own tables
    nftables.tables.agentbox = {
      family = "inet";

      content = ''
        chain forward {
          type filter hook forward priority filter; policy accept;

          iifname "agentbox" ip daddr { 10.0.0.0/8, 100.64.0.0/10, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16 } drop

          iifname "agentbox" oifname != "${config.networking.nat.externalInterface}" ct state != { established, related } drop
        }
      '';
    };
  };

  virtualisation.agentbox = {
    domain = "agentbox.${config.networking.domain}"; # every agentbox gets its own zone under it

    bridge = {
      address = "10.233.0.1";
      prefixLength = 24;
    };

    mcpProxy.port = 8080; # each agentbox's mcpproxy listens on its address here for the agent runner

    machines = {
      # keep-sorted start block=yes newline_separated=yes
      alex = {
        address = "10.233.0.3";

        preauthKeyPrefix = "d-xw9h_sSiBz";

        sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIuf9c4YZ3ymWuEyT3FLGi2x/s2D3pdwfGvxHvzxgvoR";

        flake = "github:hilorioze/agentbox-alex#agentbox-alex";
      };

      hilorioze = {
        address = "10.233.0.2";

        preauthKeyPrefix = "2xgElYczG_s3";

        sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETRRMTdO+dBh6RG00O60lVd/z36yBAbWB82ppxgyo6O";

        flake = "github:hilorioze/agentbox-hilorioze#agentbox-hilorioze";
      };

      shared = {
        address = "10.233.0.4";

        preauthKeyPrefix = "L_m4KhXohfF3";

        sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEw8SKk/R3BtflYV1p0iB4BtX5V0wg2BzbKv4TRHQpYl";

        flake = "github:hilorioze/agentbox-shared#agentbox-shared";
      };

      zikkk = {
        address = "10.233.0.5";

        preauthKeyPrefix = "wcS666VS4BCa";

        sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAsCUk89FxVkMhz695oX5FgXwpQ92g9M6QahTanphJeS";

        flake = "github:hilorioze/agentbox-zikkk#agentbox-zikkk";
      };
      # keep-sorted end
    };
  };

  systemd = {
    network = {
      enable = true;

      wait-online.enable = false; # networkd owns only the agentbox bridge, which never decides whether the host is online

      # leave the routing of sslh, tailscale and dhcpcd alone
      config.networkConfig = {
        ManageForeignRoutingPolicyRules = false;
        ManageForeignRoutes = false;
        ManageForeignNextHops = false;
      };

      netdevs."40-agentbox".netdevConfig = {
        Kind = "bridge";

        Name = "agentbox";
      };

      networks = {
        "40-agentbox" = {
          matchConfig.Name = "agentbox";

          address = ["${config.virtualisation.agentbox.bridge.address}/${toString config.virtualisation.agentbox.bridge.prefixLength}"];

          networkConfig.ConfigureWithoutCarrier = true; # keep the gateway address while no agentbox runs, so services on the host can bind to it

          linkConfig.RequiredForOnline = "no";
        };

        # the host side of every agentbox's veth
        "40-agentbox-ports" = {
          matchConfig.Name = "vb-*";

          networkConfig.Bridge = "agentbox"; # without it, networkd detaches the port nspawn enslaved

          bridgeConfig.Isolated = true; # agentboxes reach only the host, never each other

          linkConfig.RequiredForOnline = "no";
        };
      };
    };

    nspawn =
      lib.mapAttrs' (name: _machine:
        lib.nameValuePair "agentbox-${name}" {
          execConfig = {
            Boot = true;

            PrivateUsers = "pick"; # map the agentbox's root to an unprivileged range of host ids
          };

          filesConfig.PrivateUsersOwnership = "auto";

          networkConfig.Bridge = "agentbox";
        })
      config.virtualisation.agentbox.machines;

    services =
      lib.mapAttrs' (name: machine:
        lib.nameValuePair "agentbox-${name}-bootstrap" rec {
          description = "Install the first system of the ${name} agentbox";

          requiredBy = ["systemd-nspawn@agentbox-${name}.service"];
          before = requiredBy;

          after = ["network-online.target"];
          wants = ["network-online.target"];

          unitConfig.ConditionPathExists = "!/var/lib/machines/agentbox-${name}/nix/var/nix/profiles/system"; # from then on the agentbox manages its own generations, which no host deploy or reboot replaces

          path = [
            # keep-sorted start
            config.nix.package
            pkgs.nixos-install
            # keep-sorted end
          ];

          environment = {
            NIX_CONFIG = "store = /run/agentbox-bootstrap"; # `nixos-install` resolves the flake without `--store`, which would put the private source into the host's world-readable store

            NIX_USER_CONF_FILES = "%d/nix.conf";

            HOME = "/tmp"; # nix caches the fetched source under `~`, which the private tmp throws away
          };

          serviceConfig = {
            Type = "oneshot";

            LoadCredential = ["nix.conf:${config.sops.templates."agentbox-bootstrap/nix.conf".path}"];

            PrivateTmp = true;

            StateDirectory = "machines/agentbox-${name}";
            BindPaths = ["%S/machines/agentbox-${name}:/run/agentbox-bootstrap"]; # `nixos-install` wants every parent of its root world-readable, while `/var/lib/machines` keeps the agentboxes' files, owned by host ids, from the host's users
          };

          script = "nixos-install --root /run/agentbox-bootstrap --flake ${machine.flake} --no-root-passwd --no-channel-copy";
        })
      config.virtualisation.agentbox.machines
      // lib.mapAttrs' (name: _machine:
        lib.nameValuePair "systemd-nspawn@agentbox-${name}" {
          overrideStrategy = "asDropin";

          wantedBy = ["machines.target"];

          # `.nspawn` files can't pass credentials, and sops-nix's ramfs can't be idmapped for a bind mount
          serviceConfig = {
            LoadCredential = ["sops.age-key:${config.sops.secrets."services/agentbox/machines/${name}/age-key".path}"];

            ExecStart = [
              "" # replace the stock command, adding the credential
              "systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth -U --settings=override --machine=%i --load-credential=sops.age-key:sops.age-key"
            ];
          };
        })
      config.virtualisation.agentbox.machines;
  };
}
