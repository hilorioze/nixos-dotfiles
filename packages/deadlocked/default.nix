{
  # keep-sorted start
  copyDesktopItems,
  fetchFromGitHub,
  lib,
  libglvnd,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrender,
  makeDesktopItem,
  makeWrapper,
  rustPlatform,
  # keep-sorted end
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "deadlocked";

  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "avitran0";
    repo = "deadlocked";

    tag = "v${finalAttrs.version}";
    hash = "sha256-Va5QDXdrsgWCMYDlXGTLznKmi5BUWLh2/i7uC/gEfns=";
  };

  cargoHash = "sha256-Ls0nCnFbSwM9zwGgasJnkWYqKNDDjj4Eb8tSCGTyHis=";

  nativeBuildInputs = [
    # keep-sorted start
    copyDesktopItems
    makeWrapper
    # keep-sorted end
  ];

  # build only the client; the workspace also contains the radar server
  buildAndTestSubdir = "cheat";

  desktopItems = [
    (makeDesktopItem {
      name = "deadlocked";

      desktopName = "deadlocked";

      exec = "deadlocked";

      categories = ["Game"];
    })
  ];

  postInstall = let
    runtimeLibs = [
      # keep-sorted start
      libglvnd
      libx11
      libxcb
      libxcursor
      libxi
      libxkbcommon
      libxrender
      # keep-sorted end
    ];
  in ''
    wrapProgram $out/bin/deadlocked \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
  '';

  meta = {
    description = "External aimbot and ESP cheat for Counter-Strike 2";
    homepage = "https://github.com/avitran0/deadlocked";

    license = lib.licenses.gpl3Only;

    mainProgram = "deadlocked";

    platforms = ["x86_64-linux"];
  };
})
