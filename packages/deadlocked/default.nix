{
  # keep-sorted start
  alsa-lib,
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
  pkg-config,
  rustPlatform,
  # keep-sorted end
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "deadlocked";

  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "avitran0";
    repo = "deadlocked";

    tag = "v${finalAttrs.version}";
    hash = "sha256-zrQEhAboC9ytOIVYjQGHwpXOMVhVmu1ecH7UtoEBfLI=";
  };

  cargoHash = "sha256-e6oDgkrMgJtEiQ6+uSMkwkElidSIdNkGbU6wCEzyF/A=";

  nativeBuildInputs = [
    # keep-sorted start
    copyDesktopItems
    makeWrapper
    pkg-config
    # keep-sorted end
  ];

  buildInputs = [alsa-lib];

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
