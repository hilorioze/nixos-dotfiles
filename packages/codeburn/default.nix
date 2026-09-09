{
  # keep-sorted start
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildNpmPackage (finalAttrs: {
  pname = "codeburn";

  version = "0.9.24";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";

    tag = "v${finalAttrs.version}";
    hash = "sha256-opz1jon0MTPy8dCgQ2Ar4mG/PET7XD2PjLgwlle+RB8=";
  };

  npmDepsHash = "sha256-VQ7+SvDDr83tZCj53kiBFHoUx7syBFvRzgPmOJoOvDg=";

  npmBuildScript = "build:cli"; # upstream builds the web dashboard by default; build the CLI instead

  meta = {
    description = "Command-line tool for tracking AI coding token usage and cost";
    homepage = "https://github.com/getagentseal/codeburn";

    license = lib.licenses.mit;

    mainProgram = "codeburn";

    platforms = ["x86_64-linux"];
  };
})
