{
  # keep-sorted start
  cmake,
  fetchFromGitHub,
  gitMinimal,
  glm,
  lib,
  libnyquist,
  openal,
  qt5,
  spdlog,
  stdenv,
  # keep-sorted end
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "half-life-asset-manager";

  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "SamVanheer";
    repo = "HalfLifeAssetManager";

    tag = "HLAM-V${finalAttrs.version}";
    hash = "sha256-WkPRdWK+FNbe7qe91sdyq7FKckSUQxuk0WNdAMz24zU=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    # keep-sorted start
    cmake
    gitMinimal
    qt5.wrapQtAppsHook
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    glm
    libnyquist
    openal
    qt5.qtbase
    spdlog
    # keep-sorted end
  ];

  # `glm` 1.0+ requires explicit opt-in via `GLM_ENABLE_EXPERIMENTAL` for GTX headers; upstream does not declare it
  env.NIX_CFLAGS_COMPILE = "-DGLM_ENABLE_EXPERIMENTAL";

  meta = {
    description = "Tool for viewing and editing Half-Life 1 models";
    homepage = "https://github.com/SamVanheer/HalfLifeAssetManager";

    license = lib.licenses.unfreeRedistributable;

    mainProgram = "hlam";

    platforms = ["x86_64-linux"];
  };
})
