silent-sddm: final: _prev: {
  silent-sddm = (final.callPackage "${silent-sddm}/nix/package.nix" {}).overrideAttrs (oldAttrs: {
    # `installPhase` copies `$src` rather than the build directory, so `patches` never reach the output
    src = final.applyPatches {
      inherit (oldAttrs) src;

      patches = [./double-scale-fix.patch];
    };
  });
}
