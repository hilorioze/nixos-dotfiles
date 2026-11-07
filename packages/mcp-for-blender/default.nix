{
  # keep-sorted start
  buildPythonPackage,
  fetchPypi,
  httpx,
  lib,
  mcp,
  nix-update-script,
  python,
  # keep-sorted end
}: let
  # the name on pypi, independent of the package's `pname`
  pypiName = "mcp_for_blender";
in
  buildPythonPackage (finalAttrs: {
    pname = "mcp-for-blender";

    version = "2.2.7";

    src = fetchPypi {
      pname = pypiName;

      inherit (finalAttrs) version;

      format = "wheel";

      # this wheel uses `py3` in its filename and download path; override `fetchPypi`'s `py2.py3` defaults to avoid 404s
      python = "py3";
      dist = "py3";

      hash = "sha256-L9Ktb5ME+CFxZ8CNxhwYZCvAip9D+yw5iO7khRZARyw=";
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

    # the wheel url points at `files.pythonhosted.org`, which nix-update can't fetch versions from; it only recognizes `mirror://pypi`
    passthru.updateScript.command = nix-update-script {
      # `mirror://pypi` paths start with the name's first letter, and nix-update reads the name from the segment after it
      extraArgs = ["--url=mirror://pypi/${builtins.substring 0 1 pypiName}/${pypiName}"];
    };

    meta = {
      description = "MCP server and Blender add-on for controlling Blender with LLMs";
      homepage = "https://github.com/ahujasid/mcp-for-blender";

      license = lib.licenses.mit;

      mainProgram = "mcp-for-blender";

      platforms = ["x86_64-linux"];
    };
  })
