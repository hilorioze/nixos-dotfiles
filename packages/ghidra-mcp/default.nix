{
  # keep-sorted start
  buildPythonPackage,
  fetchurl,
  lib,
  mcp,
  # keep-sorted end
}:
buildPythonPackage (finalAttrs: {
  pname = "ghidra-mcp";

  version = "6.0.0";

  src = fetchurl {
    url = "https://github.com/bethington/ghidra-mcp/releases/download/v${finalAttrs.version}/ghidra_mcp_bridge-${finalAttrs.version}-py3-none-any.whl";

    hash = "sha256-cZOaiQAJgmZkcgFm2PeG86LqJGD37/zYPHN1m6QkEzQ=";
  };

  format = "wheel";

  dependencies = [mcp];

  # nixpkgs ships mcp 1.26.0, but upstream requires >=1.28.1
  pythonRelaxDeps = ["mcp"];

  meta = {
    description = "Model Context Protocol server for Ghidra reverse engineering";
    homepage = "https://github.com/bethington/ghidra-mcp";

    license = lib.licenses.asl20;

    mainProgram = "bridge-mcp-ghidra";

    platforms = ["x86_64-linux"];
  };
})
