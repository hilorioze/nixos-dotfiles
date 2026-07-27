_final: prev: {
  nix-update-script = args:
    prev.nix-update-script (
      args
      // {
        extraArgs = (args.extraArgs or []) ++ ["--flake"];
      }
    );
}
