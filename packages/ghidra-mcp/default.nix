{
  # keep-sorted start
  fetchFromGitHub,
  lib,
  makeWrapper,
  python3Packages,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ghidra-mcp";

  version = "5.4.1";

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";

    tag = "v${finalAttrs.version}";
    hash = "sha256-ZyCOoFlVbEDMUwUksxci005XbfkrW5vUwbyWBQiXQZw=";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [makeWrapper];

  propagatedBuildInputs = with python3Packages; [
    # keep-sorted start
    mcp
    requests
    # keep-sorted end
  ];

  installPhase = ''
    runHook preInstall

    install -Dm444 bridge_mcp_ghidra.py "$out/share/ghidra-mcp/bridge_mcp_ghidra.py"

    makeWrapper ${python3Packages.python.interpreter} "$out/bin/ghidra-mcp" \
      --prefix PYTHONPATH : ${python3Packages.makePythonPath finalAttrs.propagatedBuildInputs} \
      --add-flags "$out/share/ghidra-mcp/bridge_mcp_ghidra.py"

    runHook postInstall
  '';

  meta = {
    description = "Model Context Protocol server for Ghidra reverse engineering";
    homepage = "https://github.com/bethington/ghidra-mcp";

    license = lib.licenses.asl20;

    mainProgram = "ghidra-mcp";

    platforms = ["x86_64-linux"];
  };
})
