{
  # keep-sorted start
  buildPythonPackage,
  fetchurl,
  lib,
  mcp,
  nix-update-script,
  pydantic,
  # keep-sorted end
}:
buildPythonPackage (finalAttrs: {
  pname = "ghidra-mcp";

  version = "7.1.0";

  src = fetchurl {
    url = "https://github.com/bethington/ghidra-mcp/releases/download/v${finalAttrs.version}/ghidra_mcp_bridge-${finalAttrs.version}-py3-none-any.whl";

    hash = "sha256-y+7o4DmDj22F8ukZOSN2XWt7/rcduKNdF2N3EZhCSGs=";
  };

  format = "wheel";

  dependencies = [
    # keep-sorted start
    mcp
    pydantic
    # keep-sorted end
  ];

  # nixpkgs ships mcp 1.26.0, but upstream requires >=1.28.1
  pythonRelaxDeps = ["mcp"];

  # upstream tags versions it never publishes as a release, such as `v7.1.0`, so a tag can have no wheel; follow published releases
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--use-github-releases"];
  };

  meta = {
    description = "MCP bridge exposing Ghidra reverse engineering tools to AI clients";
    homepage = "https://github.com/bethington/ghidra-mcp";

    license = lib.licenses.asl20;

    mainProgram = "bridge-mcp-ghidra";

    platforms = ["x86_64-linux"];
  };
})
