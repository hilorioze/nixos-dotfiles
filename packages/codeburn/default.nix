{
  # keep-sorted start
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildNpmPackage (finalAttrs: {
  pname = "codeburn";

  version = "0.9.26";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";

    tag = "v${finalAttrs.version}";
    hash = "sha256-+mU3eys0pRFCMd/dh8D/FqElAToTBMuIB2U+upcO0C8=";
  };

  npmDepsHash = "sha256-W/Q+nLFrT10soNwdklDW/j+G++yRaQ3pA9BdGd33auQ=";

  npmBuildScript = "build:cli"; # upstream builds the web dashboard by default; build the CLI instead

  meta = {
    description = "Command-line tool for tracking AI coding token usage and cost";
    homepage = "https://github.com/getagentseal/codeburn";

    license = lib.licenses.mit;

    mainProgram = "codeburn";

    platforms = ["x86_64-linux"];
  };
})
