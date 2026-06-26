{
  # keep-sorted start
  fetchFromGitHub,
  ghidra,
  lib,
  # keep-sorted end
}:
ghidra.buildGhidraExtension (finalAttrs: {
  pname = "ghidra-mcp-plugin";

  version = "5.4.1";

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";

    tag = "v${finalAttrs.version}";
    hash = "sha256-ZyCOoFlVbEDMUwUksxci005XbfkrW5vUwbyWBQiXQZw=";
  };

  meta = {
    description = "Ghidra plugin exposing program data via the Model Context Protocol";
    homepage = "https://github.com/bethington/ghidra-mcp";

    license = lib.licenses.asl20;

    platforms = ["x86_64-linux"];
  };
})
