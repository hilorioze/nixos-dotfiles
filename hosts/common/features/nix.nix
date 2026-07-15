{inputs, ...}: let
  inherit ((import ../../../flake.nix)) nixConfig;
in {
  nix = {
    # pin system channels to flake inputs
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];

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
