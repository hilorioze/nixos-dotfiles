_final: prev: {
  unstablePkgs = prev.unstablePkgs.extend (unstableFinal: unstablePrev: {
    # nixpkgs hands claude alsa-lib through `LD_LIBRARY_PATH` for the voice mode module, and every child inherits it:
    # a program built against an older glibc that links alsa (ffmpeg) then fails to start
    # `DT_RPATH` on claude itself covers libraries of modules it loads, `DT_RUNPATH` doesn't
    claude-code = unstablePrev.claude-code.overrideAttrs (oldAttrs: {
      installPhase = builtins.replaceStrings ["--prefix LD_LIBRARY_PATH : ${unstableFinal.lib.makeLibraryPath [unstableFinal.alsa-lib]} \\\n"] [""] oldAttrs.installPhase;

      postFixup = let
        patchelf = unstableFinal.patchelf.overrideAttrs (patchelfAttrs: {
          # fix `DT_VERDEF` relocation so adding rpath doesn't crash claude before startup
          patches =
            (patchelfAttrs.patches or [])
            ++ [
              (unstableFinal.fetchpatch {
                url = "https://github.com/NixOS/patchelf/commit/efc11141bdc373a219db53a1c699bc4fde3a23b8.patch";
                hash = "sha256-H3oPqD1UucM5/+nVEZ1FJNUwbvDSVckIFty0Fid+3oA=";

                includes = ["src/patchelf.cc"];
              })
            ];
        });
      in
        (oldAttrs.postFixup or "")
        + ''
          ${unstableFinal.lib.getExe patchelf} --force-rpath --add-rpath ${unstableFinal.lib.makeLibraryPath [unstableFinal.alsa-lib]} $out/bin/.claude-wrapped
        '';
    });
  });
}
