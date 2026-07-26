{
  # keep-sorted start
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  lib,
  mcp,
  # keep-sorted end
}:
buildPythonPackage (finalAttrs: {
  pname = "ghidra-mcp";

  version = "6.0.0";

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";

    tag = "v${finalAttrs.version}";
    hash = "sha256-LnhhJwycO8NQV+YaTP7ZoxGkoGLkc14BwY66wczbpp0=";
  };

  pyproject = true;

  build-system = [hatchling];

  dependencies = [mcp];

  meta = {
    description = "Model Context Protocol server for Ghidra reverse engineering";
    homepage = "https://github.com/bethington/ghidra-mcp";

    license = lib.licenses.asl20;

    mainProgram = "bridge-mcp-ghidra";

    platforms = ["x86_64-linux"];
  };
})
