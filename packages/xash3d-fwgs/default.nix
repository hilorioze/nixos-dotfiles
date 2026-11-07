{
  # keep-sorted start
  SDL2,
  bzip2,
  ensureNewerSourcesForZipFilesHook,
  fetchFromGitHub,
  freetype,
  lib,
  libogg,
  libopus,
  libvorbis,
  libx11,
  makeWrapper,
  nix-update-script,
  opusfile,
  pkg-config,
  python3,
  stdenv,
  wafHook,
  # keep-sorted end
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xash3d-fwgs";

  version = "0-unstable-2026-11-06";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "xash3d-fwgs";

    rev = "e9b94dc1a89bcd8867e2d16b37cd6f1cbd4dbd1c";
    hash = "sha256-8urzzsGV/Y4c+a8nIeAT/NImZaRDrCPaMC59Yy5Fe1g=";

    fetchSubmodules = true;
  };

  # without `.git` waf bakes `None` as the commit date, the engine then reports build number `-1` and mods refuse to start
  postPatch = ''
    substituteInPlace public/wscript \
      --replace-fail "conf.get_git_commit_date()" "'${builtins.head (builtins.match "0-unstable-(.+)" finalAttrs.version)}'"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    # keep-sorted start
    ensureNewerSourcesForZipFilesHook
    makeWrapper
    pkg-config
    python3
    wafHook
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    SDL2
    bzip2
    freetype
    libogg
    libopus
    libvorbis
    libx11
    opusfile
    # keep-sorted end
  ];

  dontAddPrefix = true;

  wafConfigureFlags = ["--64bits"];

  wafInstallFlags = ["--destdir=${placeholder "out"}/lib"];

  postInstall = ''
    makeWrapper $out/lib/xash3d $out/bin/xash3d \
      --set XASH3D_RODIR $out/lib/valve \
      --run 'export XASH3D_BASEDIR=$HOME/.xash3d/'
  '';

  # upstream only moves `continuous*` prerelease tags; follow `master` and keep them out of the version
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--version=branch" "--version-regex=^(0-unstable-.+)$"];
  };

  meta = {
    description = "GoldSrc-compatible game engine";
    homepage = "https://github.com/FWGS/xash3d-fwgs";

    license = lib.licenses.gpl3Plus;

    mainProgram = "xash3d";

    platforms = ["x86_64-linux"];
  };
})
