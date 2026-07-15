{
  nix.settings = let
    inherit ((import ../../../flake.nix)) nixConfig;
  in
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
}
