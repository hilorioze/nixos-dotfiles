_final: prev: {
  nix-monitored = prev.nix-monitored.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./notification-utf8-fix.patch
      ];
  });
}
