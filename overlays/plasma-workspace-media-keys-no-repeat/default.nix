_final: prev: {
  kdePackages =
    prev.kdePackages
    // {
      plasma-workspace = prev.kdePackages.plasma-workspace.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [
            ./media-keys-no-repeat.patch
          ];
      });
    };
}
