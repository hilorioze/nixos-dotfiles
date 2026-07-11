{inputs, ...}: let
  inherit ((import ../../../flake.nix)) nixConfig;

  nixpkgsUnfreePath = inputs.nixpkgs-unfree.outPath;
in {
  nixpkgs.flake = {
    # disable nixpkgs' generated `NIX_PATH`; `nix.nixPath` below sets it explicitly
    setNixPath = false;

    # disable nixpkgs' generated registry entry; `nix.registry.nixpkgs.flake` below sets it explicitly
    setFlakeRegistry = false;
  };

  nix = {
    # route legacy `<nixpkgs>` lookups, including comma's `NIX_PATH` handling, through `nixpkgs-unfree`
    nixPath = ["nixpkgs=${nixpkgsUnfreePath}"];

    # route CLI `nixpkgs#...` lookups through `nixpkgs-unfree`
    registry.nixpkgs.flake = inputs.nixpkgs-unfree;

    settings =
      {
        # keep-sorted start block=yes newline_separated=yes
        experimental-features = [
          # keep-sorted start
          "flakes"
          "nix-command"
          # keep-sorted end
        ];

        trusted-users = [
          # keep-sorted start
          "@wheel"
          "deployer"
          # keep-sorted end
        ];
        # keep-sorted end
      }
      // nixConfig;
  };
}
