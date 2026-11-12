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

  version = "0-unstable-2026-11-10";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "xash3d-fwgs";

    rev = "707596f4905689ec224e993fcaa4d4ad66aa67d6";
    hash = "sha256-qclKeXMUy7ocNp4AqkAXyFS1aSQO4vlKb1SfnTp/sMo=";

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
