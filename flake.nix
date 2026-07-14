{
  nixConfig = {
    # keep-sorted start block=yes newline_separated=yes
    extra-substituters = [
      # https://cache.nixos.org has priority 40
      "https://nix-cache.hilorioze.com?priority=41"
      "https://cache.nixos-cuda.org?priority=42"
      "https://nix-community.cachix.org?priority=43"
      "https://nix-gaming.cachix.org?priority=44"
    ];

    extra-trusted-public-keys = [
      "nix-cache.hilorioze.com-1:vKKWGjVDgXl/TXbUWuPWTnDhhDit6hqkTcuoGfter5Y="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
    # keep-sorted end
  };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    # keep-sorted start block=yes newline_separated=yes
    deploy-rs = {
      url = "github:serokell/deploy-rs";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    # keep-sorted end

    # keep-sorted start block=yes newline_separated=yes
    cstrike-mod.url = "github:hilorioze/cstrike-mod"; # keep their inputs for binary cache

    direnv-instant = {
      url = "github:Mic92/direnv-instant";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    ffmpeg-mcp-lite = {
      url = "github:kevinwatt/ffmpeg-mcp-lite";

      flake = false;
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    freesmlauncher.url = "github:FreesmTeam/FreesmLauncher"; # keep their inputs for binary cache

    mcp-nixos = {
      url = "github:utensils/mcp-nixos";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    mt7927-nixos = {
      url = "github:cmspam/mt7927-nixos";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    niks3 = {
      url = "github:Mic92/niks3";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";

      inputs = {
        nixpkgs.follows = "nixpkgs";

        nix-index-database.follows = "nix-index-database";
      };
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nix-gaming.url = "github:fufexan/nix-gaming"; # keep their inputs for binary cache

    nix-index-database = {
      url = "github:nix-community/nix-index-database";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-monitored = {
      url = "github:ners/nix-monitored";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-software-center = {
      url = "github:snowfallorg/nix-software-center";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-conf-editor = {
      url = "github:snowfallorg/nixos-conf-editor";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    opencode-wakatime = {
      url = "github:angristan/opencode-wakatime";

      flake = false;
    };

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
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/main";

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

    stylix = {
      url = "github:nix-community/stylix";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    yt-dlp-mcp = {
      url = "github:kevinwatt/yt-dlp-mcp";

      flake = false;
    };
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

    systems = [
      # keep-sorted start
      "aarch64-linux"
      "x86_64-linux"
      # keep-sorted end
    ];
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      inherit systems;

      perSystem = {pkgs, ...}: {
        packages = import ./packages {
          inherit lib;

          pkgs = pkgs.extend (lib.composeManyExtensions (builtins.attrValues inputs.self.overlays));
        };
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

        mkDeployNode = nixosConfiguration: {
          hostname = nixosConfiguration.config.networking.fqdn;

          sshUser = "deployer";

          profiles.system = {
            user = "root";

            path = deploy-rs.lib.${nixosConfiguration.config.nixpkgs.hostPlatform.system}.activate.nixos nixosConfiguration;
          };
        };
      in {
        inherit systems; # exported for `atelier` CI discovery

        lib = lib';

        nixosModules = import ./modules/nixos;
        homeModules = import ./modules/home-manager;

        overlays = import ./overlays {inherit inputs;};

        nixosConfigurations = {
          # keep-sorted start
          de0 = mkNixosSystem [./hosts/de0];
          fakesynology-nixos = mkNixosSystem [./hosts/fakesynology-nixos];
          hel0 = mkNixosSystem [./hosts/hel0];
          hilonix = mkNixosSystem [./hosts/hilonix];
          hisonix = mkNixosSystem [./hosts/hisonix];
          lelonix = mkNixosSystem [./hosts/lelonix];
          zikkkix = mkNixosSystem [./hosts/zikkkix];
          # keep-sorted end
        };

        deploy.nodes = {
          # keep-sorted start
          de0 = mkDeployNode config.nixosConfigurations.de0;
          fakesynology-nixos = mkDeployNode config.nixosConfigurations.fakesynology-nixos;
          hel0 = mkDeployNode config.nixosConfigurations.hel0;
          hilonix = mkDeployNode config.nixosConfigurations.hilonix;
          lelonix = mkDeployNode config.nixosConfigurations.lelonix;
          zikkkix = mkDeployNode config.nixosConfigurations.zikkkix;
          # keep-sorted end
        };
      };
    };
}
