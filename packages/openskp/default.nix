{
  # keep-sorted start
  buildPythonPackage,
  defusedxml,
  fetchPypi,
  lib,
  mapbox-earcut,
  numpy,
  shapely,
  trimesh,
  # keep-sorted end
}:
buildPythonPackage (finalAttrs: {
  pname = "openskp";

  version = "1.5.0";

  src = fetchPypi {
    inherit (finalAttrs) pname version;

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

  meta = {
    description = "SketchUp (.skp) reader, writer, and converter";
    homepage = "https://github.com/iamahsanmehmood/openskp";

    license = lib.licenses.mit;

    mainProgram = "openskp";

    platforms = ["x86_64-linux"];
  };
})
