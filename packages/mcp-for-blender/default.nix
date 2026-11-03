{
  # keep-sorted start
  buildPythonPackage,
  fetchPypi,
  httpx,
  lib,
  mcp,
  python,
  # keep-sorted end
}:
buildPythonPackage (finalAttrs: {
  pname = "mcp-for-blender";

  version = "2.2.6";

  src = fetchPypi {
    pname = "mcp_for_blender";

    inherit (finalAttrs) version;

    format = "wheel";

    # this wheel uses `py3` in its filename and download path; override `fetchPypi`'s `py2.py3` defaults to avoid 404s
    python = "py3";
    dist = "py3";

    hash = "sha256-b0fO9qW14ghCafzewCf6jG+wlxV/G/Ms2SKnEeWdc4w=";
  };

  format = "wheel";

  dependencies = [
    # keep-sorted start
    httpx
    mcp
    # keep-sorted end
  ];

  postInstall = ''
    install -D --mode=644 $out/${python.sitePackages}/blender_mcp/bundled/addon.py $out/share/blender/addons/blender_mcp.py
  '';

  meta = {
    description = "MCP server and Blender plugin for LLM control";
    homepage = "https://github.com/ahujasid/mcp-for-blender";

    license = lib.licenses.mit;

    mainProgram = "mcp-for-blender";

    platforms = ["x86_64-linux"];
  };
})
