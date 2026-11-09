{
  nixConfig = {
    # keep-sorted start block=yes newline_separated=yes
    always-allow-substitutes = true;

    extra-substituters = [
      # https://cache.nixos.org has priority 40
      "https://nix-cache.hilorioze.com?priority=41"
      "https://cache.nixos-cuda.org?priority=42"
      "https://nix-community.cachix.org?priority=43"
    ];

    extra-trusted-public-keys = [
      "nix-cache.hilorioze.com-1:vKKWGjVDgXl/TXbUWuPWTnDhhDit6hqkTcuoGfter5Y="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    # keep-sorted end
  };

  inputs = {
    # keep-sorted start block=yes newline_separated=yes
    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";
    # keep-sorted end

    # keep-sorted start block=yes newline_separated=yes
    deploy-rs = {
      url = "github:serokell/deploy-rs";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable-small.url = "github:nixos/nixpkgs/nixos-unstable-small";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # keep-sorted end

    # keep-sorted start block=yes newline_separated=yes
    authentik-nix.url = "github:nix-community/authentik-nix"; # keep their inputs for binary cache

    claude-code-wakatime = {
      url = "github:wakatime/claude-code-wakatime";

      flake = false;
    };

    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";

      flake = false;
    };

    cstrike-mod.url = "github:hilorioze/cstrike-mod"; # keep their inputs for binary cache

    disko = {
      url = "github:nix-community/disko/latest";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    freesmlauncher = {
      url = "github:FreesmTeam/FreesmLauncher";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    lazyvim-nix = {
      url = "github:pfassina/lazyvim-nix";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    mud.url = "github:hilorioze/mud"; # keep their inputs for binary cache

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nix-gaming = {
      url = "github:fufexan/nix-gaming";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-monitored = {
      url = "github:ners/nix-monitored";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions"; # keep upstream's tested nixpkgs pin for its own outputs and extension fixes

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";

      inputs = {
        nixpkgs.follows = "nixpkgs";

        home-manager.follows = "home-manager";
      };
    };

    silent-sddm = {
      url = "github:uiriansan/SilentSDDM";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    steam-config-nix = {
      url = "github:different-name/steam-config-nix";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    steam-voicechat-fix.url = "github:hilorioze/steam-voicechat-fix"; # keep their inputs for binary cache

    stylix.url = "github:nix-community/stylix/release-26.05"; # keep their inputs for binary cache
    # keep-sorted end
  };

  outputs = inputs @ {
    # keep-sorted start
    deploy-rs,
    flake-parts,
    nixpkgs,
    # keep-sorted end
    ...
  }: let
    inherit (nixpkgs) lib;
    lib' = import ./lib {inherit lib;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        # keep-sorted start
        "aarch64-linux"
        "x86_64-linux"
        # keep-sorted end
      ];

      perSystem = {pkgs, ...}: let
        pkgs' = pkgs.extend inputs.self.overlays.default;
      in {
        apps = {
          # keep-sorted start
          devenv.program = lib.getExe pkgs'.devenv; # expose the overlaid devenv package to `.github/workflows/{build-devenv,update-devenv-lock}.yaml`
          nix-update.program = lib.getExe pkgs'.nix-update; # expose the locally patched nix-update package to `.github/workflows/update-packages.yaml`
          # keep-sorted end
        };

        packages = import ./packages {
          inherit lib;

          pkgs = pkgs';
        };

        legacyPackages.niks3 = pkgs'.unstablePkgs.niks3; # expose nixpkgs' niks3 client to the workflows
      };

      flake = {config, ...}: let
        mkNixosSystem = modules:
          lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              inherit lib';

              outputs = config;
            };

            inherit modules;
          };

        mkDeployNode = nixosConfiguration: let
          inherit (nixosConfiguration) pkgs;

          # keep the pinned deploy-rs lib, but use nixpkgs' cached binary to avoid rebuilding deploy-rs from source
          deployLib =
            (
              deploy-rs.overlays.default
              (
                pkgs
                // {
                  deploy-rs = {
                    inherit (pkgs) deploy-rs;
                  };
                }
              )
              pkgs
            ).deploy-rs.lib;
        in {
          hostname = nixosConfiguration.config.networking.fqdn;

          sshUser = nixosConfiguration.config.users.users.deployer.name;

          # reuse one authenticated connection during deployment
          sshOpts = [
            "-o"
            "ControlMaster=auto"
            "-o"
            "ControlPersist=10m"
            "-o"
            "ControlPath=~/.ssh/deploy-rs-%C"
          ];

          profiles.system = {
            user = "root";

            path = deployLib.activate.nixos nixosConfiguration;
          };
        };
      in {
        lib = lib';

        nixosModules = import ./modules/nixos;
        homeModules = import ./modules/home-manager;

        overlays.default = lib.composeManyExtensions (import ./overlays {inherit inputs;});

        nixosConfigurations = {
          # keep-sorted start
          de0 = mkNixosSystem [./hosts/de0];
          fakesynology-nixos = mkNixosSystem [./hosts/fakesynology-nixos];
          hel0 = mkNixosSystem [./hosts/hel0];
          hilonix = mkNixosSystem [./hosts/hilonix];
          hisonix = mkNixosSystem [./hosts/hisonix];
          lelonix = mkNixosSystem [./hosts/lelonix];
          # keep-sorted end
        };

        deploy.nodes = {
          # keep-sorted start
          de0 = mkDeployNode config.nixosConfigurations.de0;
          fakesynology-nixos = mkDeployNode config.nixosConfigurations.fakesynology-nixos;
          hel0 = mkDeployNode config.nixosConfigurations.hel0;
          hilonix = mkDeployNode config.nixosConfigurations.hilonix;
          lelonix = mkDeployNode config.nixosConfigurations.lelonix;
          # keep-sorted end
        };
      };
    };
}
