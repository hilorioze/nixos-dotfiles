{
  # keep-sorted start
  babel,
  buildPythonPackage,
  curl-cffi,
  fastapi,
  fastmcp,
  fetchPypi,
  httpx,
  lib,
  mcp,
  nix-update-script,
  plotext,
  pydantic,
  pydantic-settings,
  python-dotenv,
  ratelimit,
  rich,
  starlette,
  tenacity,
  typer,
  uvicorn,
  # keep-sorted end
}: let
  # the name on pypi, independent of the package's `pname`
  pypiName = "flights";
in
  buildPythonPackage (finalAttrs: {
    pname = "fli";

    version = "0.11.1";

    src = fetchPypi {
      pname = pypiName;

      inherit (finalAttrs) version;
      hash = "sha256-InYcG8KMSD9On4kL5QIDeRS7RuFSSFRRyJrNEzKEvws=";

      format = "wheel";

      # this wheel uses `py3` in its filename and download path; override `fetchPypi`'s `py2.py3` defaults to avoid 404s
      python = "py3";
      dist = "py3";
    };

    format = "wheel";

    dependencies = [
      # keep-sorted start
      babel
      curl-cffi
      httpx
      plotext
      pydantic
      python-dotenv
      ratelimit
      rich
      tenacity
      typer
      # keep-sorted end

      # the `mcp` extra, which `fli-mcp` needs
      # keep-sorted start
      fastapi
      fastmcp
      mcp
      pydantic-settings
      starlette
      uvicorn
      # keep-sorted end
    ];

    # nixpkgs ships curl-cffi 0.14.0, but upstream requires >=0.15.0
    pythonRelaxDeps = ["curl-cffi"];

    # the wheel url points at `files.pythonhosted.org`, which nix-update can't fetch versions from; it only recognizes `mirror://pypi`
    passthru.updateScript.command = nix-update-script {
      # `mirror://pypi` paths start with the name's first letter, and nix-update reads the name from the segment after it
      extraArgs = ["--url=mirror://pypi/${builtins.substring 0 1 pypiName}/${pypiName}"];
    };

    meta = {
      description = "MCP server and CLI for searching Google Flights";
      homepage = "https://github.com/punitarani/fli";

      license = lib.licenses.mit;

      mainProgram = "fli-mcp";

      platforms = ["x86_64-linux"];
    };
  })
