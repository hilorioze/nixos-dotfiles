{
  # keep-sorted start
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildNpmPackage (finalAttrs: {
  pname = "codeburn";

  version = "0.9.27";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";

    tag = "v${finalAttrs.version}";
    hash = "sha256-P00axAx78eVa6O2P+5F0aqooPCtX9G1phg3ZgEDFNPE=";
  };

  npmDepsHash = "sha256-dz5S3Sajk3QllMDGQu1GO2ws6IAq5dYN3HqDyJI5ryM=";

  npmBuildScript = "build:cli"; # upstream builds the web dashboard by default; build the CLI instead

  meta = {
    description = "Command-line tool for tracking AI coding token usage and cost";
    homepage = "https://github.com/getagentseal/codeburn";

    license = lib.licenses.mit;

    mainProgram = "codeburn";

    platforms = ["x86_64-linux"];
  };
})
