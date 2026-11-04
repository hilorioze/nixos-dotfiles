{
  # keep-sorted start
  buildPythonPackage,
  defusedxml,
  fetchPypi,
  lib,
  mapbox-earcut,
  nix-update-script,
  numpy,
  shapely,
  trimesh,
  # keep-sorted end
}: let
  # the name on pypi, independent of the package's `pname`
  pypiName = "openskp";
in
  buildPythonPackage (finalAttrs: {
    pname = "openskp";

    version = "1.5.0";

    src = fetchPypi {
      pname = pypiName;

      inherit (finalAttrs) version;

      format = "wheel";

      # this wheel uses `py3` in its filename and download path; override `fetchPypi`'s `py2.py3` defaults to avoid 404s
      python = "py3";
      dist = "py3";

      hash = "sha256-/kz11AzZjPayDbwFLq3W5kN7/UW4XkqHtX0/ng5t4/0=";
    };

    format = "wheel";

    dependencies = [
      # keep-sorted start
      defusedxml
      mapbox-earcut
      numpy
      shapely
      trimesh
      # keep-sorted end
    ];

    # the wheel url points at `files.pythonhosted.org`, which nix-update can't fetch versions from; it only recognizes `mirror://pypi`
    passthru.updateScript.command = nix-update-script {
      # `mirror://pypi` paths start with the name's first letter, and nix-update reads the name from the segment after it
      extraArgs = ["--url=mirror://pypi/${builtins.substring 0 1 pypiName}/${pypiName}"];
    };

    meta = {
      description = "SketchUp (.skp) reader, writer, and converter";
      homepage = "https://github.com/iamahsanmehmood/openskp";

      license = lib.licenses.mit;

      mainProgram = "openskp";

      platforms = ["x86_64-linux"];
    };
  })
