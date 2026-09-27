{
  # keep-sorted start
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildNpmPackage (finalAttrs: {
  pname = "codeburn";

  version = "0.9.25";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";

    tag = "v${finalAttrs.version}";
    hash = "sha256-MVgXl+fN9qZZmXhlgLXTX0toldDM1oH99Mc5bxScu7g=";
  };

  npmDepsHash = "sha256-ucqpt5HTi8d8sD9eUl9ja7PyG0kyy1TASXgii/0xaNk=";

  npmBuildScript = "build:cli"; # upstream builds the web dashboard by default; build the CLI instead

  meta = {
    description = "Command-line tool for tracking AI coding token usage and cost";
    homepage = "https://github.com/getagentseal/codeburn";

    license = lib.licenses.mit;

    mainProgram = "codeburn";

    platforms = ["x86_64-linux"];
  };
})
