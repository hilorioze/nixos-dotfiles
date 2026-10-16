{
  # keep-sorted start
  capstone,
  cmake,
  fetchFromGitHub,
  git,
  icu,
  lib,
  makeWrapper,
  ninja,
  nix-update-script,
  pkg-config,
  python3,
  stdenv,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "blutter";

  version = "0-unstable-2026-08-18";

  src = fetchFromGitHub {
    owner = "worawit";
    repo = "blutter";

    rev = "4a60ac648bf448c5a7596437243bcd0b9376fdf0";
    hash = "sha256-tmDCfTEItJHobOjquDb726O/0xquqc/n3VxNRu+SHlc=";
  };

  nativeBuildInputs = [makeWrapper];

  # builds the dart vm of each analysed app next to its own sources, so it runs from a writable copy
  installPhase = let
    python = python3.withPackages (pythonPackages:
      with pythonPackages; [
        # keep-sorted start
        pyelftools
        requests
        # keep-sorted end
      ]);

    workDir = "$HOME/.cache/blutter/${finalAttrs.version}";
  in ''
    runHook preInstall

    mkdir --parents $out/share
    cp --recursive . $out/share/blutter

    makeWrapper ${lib.getExe python} $out/bin/${finalAttrs.meta.mainProgram} \
      --run 'mkdir --parents ${workDir}' \
      --run 'cp --recursive --no-preserve=mode --update=none ${placeholder "out"}/share/blutter/. ${workDir}' \
      --add-flags '${workDir}/blutter.py' \
      --prefix PATH : ${lib.makeBinPath [cmake git ninja pkg-config stdenv.cc]} \
      --prefix CMAKE_PREFIX_PATH : ${lib.getDev icu}:${lib.getLib icu} \
      --prefix PKG_CONFIG_PATH : ${lib.getDev capstone}/lib/pkgconfig \
      --prefix CPLUS_INCLUDE_PATH : ${lib.getDev capstone}/include/capstone \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [capstone icu]}

    runHook postInstall
  '';

  # upstream has no releases; follow `main` instead
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--version=branch"];
  };

  meta = {
    description = "Flutter mobile application reverse engineering tool";
    homepage = "https://github.com/worawit/blutter";

    license = lib.licenses.mit;

    mainProgram = "blutter";

    platforms = ["x86_64-linux"];
  };
})
