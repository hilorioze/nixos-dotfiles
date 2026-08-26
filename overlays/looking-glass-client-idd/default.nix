final: prev: {
  looking-glass-client = prev.looking-glass-client.overrideAttrs (oldAttrs: {
    version = "B7-unstable-2026-08-25";

    src = oldAttrs.src.overrideAttrs (_: {
      rev = "54ea580e35d8f3c96ab6177ff284d1d047796bf7";
      hash = "sha256-gHVred8rgwTeRTW0AXxMlnz/ovXv6w9SyknVHiW3pKU=";
    });

    patches = []; # drop inherited `nixpkgs`' `nanosvg` unvendor patch; upstream can build with vendored again

    buildInputs =
      (final.lib.remove prev.nanosvg oldAttrs.buildInputs) # drop inherited `nixpkgs`' `nanosvg` dependency; upstream can use vendored again
      ++ (with final; [
        # keep-sorted start
        fuse3
        usbredir # for USB audio support
        # keep-sorted end
      ]);

    cmakeFlags =
      oldAttrs.cmakeFlags
      ++ [
        (final.lib.cmakeBool "ENABLE_BACKTRACE" false) # avoid `elfutils` and `libunwind` build dependencies required only for crash backtraces
      ];
  });
}
