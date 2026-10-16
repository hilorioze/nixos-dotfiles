{
  nix.settings = let
    inherit ((import ../../../flake.nix)) nixConfig;
  in
    {
      # keep-sorted start block=yes newline_separated=yes
      auto-optimise-store = true;

      experimental-features = [
        # keep-sorted start
        "flakes"
        "nix-command"
        # keep-sorted end
      ];

      max-free = 30 * 1024 * 1024 * 1024; # 30G

      min-free = 10 * 1024 * 1024 * 1024; # 10G; collect garbage only when a build runs low on space

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
