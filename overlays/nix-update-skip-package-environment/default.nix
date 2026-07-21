_final: prev: {
  nix-update = prev.nix-update.overrideAttrs (previousAttrs: {
    patches =
      (previousAttrs.patches or [])
      ++ [
        ./skip-package-environment.patch
      ];
  });
}
