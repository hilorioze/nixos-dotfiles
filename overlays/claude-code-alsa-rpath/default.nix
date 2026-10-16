_final: prev: {
  unstablePkgs =
    prev.unstablePkgs
    // {
      # nixpkgs hands claude alsa-lib through `LD_LIBRARY_PATH` for the voice mode module, and every child inherits it:
      # a program built against an older glibc that links alsa (ffmpeg) then fails to start
      # `DT_RPATH` on claude itself covers libraries of modules it loads, `DT_RUNPATH` doesn't
      claude-code = prev.unstablePkgs.claude-code.overrideAttrs (oldAttrs: {
        installPhase = builtins.replaceStrings ["--prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath [prev.unstablePkgs.alsa-lib]} \\\n"] [""] oldAttrs.installPhase;

        postFixup = ''
          patchelf --force-rpath --add-rpath ${prev.lib.makeLibraryPath [prev.unstablePkgs.alsa-lib]} $out/bin/.claude-wrapped
        '';
      });
    };
}
