{
  # keep-sorted start
  fetchFromGitHub,
  ghidra,
  lib,
  # keep-sorted end
}:
ghidra.buildGhidraExtension (finalAttrs: {
  pname = "ghidra-mcp-plugin";

  version = "6.0.0";

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";

    tag = "v${finalAttrs.version}";
    hash = "sha256-LnhhJwycO8NQV+YaTP7ZoxGkoGLkc14BwY66wczbpp0=";
  };

  # `build.gradle` writes the extension zip to `build/distributions/` instead of `dist/`
  # unpack it into ghidra's extension layout and add `.dbDirLock` so ghidra won't create lock files in the nix store
  installPhase = ''
    runHook preInstall

    extension_dir=$out/lib/ghidra/Ghidra/Extensions/GhidraMCP

    mkdir --parents $extension_dir
    unzip -d $out/lib/ghidra/Ghidra/Extensions build/distributions/GhidraMCP-${finalAttrs.version}.zip
    touch $extension_dir/.dbDirLock

    runHook postInstall
  '';

  meta = {
    description = "Ghidra plugin exposing program data via the Model Context Protocol";
    homepage = "https://github.com/bethington/ghidra-mcp";

    license = lib.licenses.asl20;

    platforms = ["x86_64-linux"];
  };
})
