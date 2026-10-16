{
  # keep-sorted start
  alsa-lib,
  autoPatchelfHook,
  copyDesktopItems,
  fetchurl,
  lib,
  libgcc,
  libglvnd,
  libx11,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrender,
  makeDesktopItem,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "deadlocked";

  version = "1.4.1";

  src = fetchurl {
    url = "https://github.com/avitran0/deadlocked/releases/download/v${finalAttrs.version}/deadlocked";

    hash = "sha256-wpl8Q6RIcPz5DbXITayqhvZ18PjwqvipFN/weLnj+bk=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    # keep-sorted start
    autoPatchelfHook
    copyDesktopItems
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    alsa-lib
    libgcc
    # keep-sorted end
  ];

  # loaded with `dlopen`
  runtimeDependencies = [
    # keep-sorted start
    libglvnd
    libx11
    libxcursor
    libxi
    libxkbcommon
    libxrender
    # keep-sorted end
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "deadlocked";

      desktopName = "deadlocked";

      exec = finalAttrs.meta.mainProgram;

      categories = ["Game"];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -D --mode=755 $src $out/bin/${finalAttrs.meta.mainProgram}

    runHook postInstall
  '';

  meta = {
    description = "External aimbot and ESP cheat for Counter-Strike 2";
    homepage = "https://github.com/avitran0/deadlocked";

    license = lib.licenses.gpl3Only;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];

    mainProgram = "deadlocked";

    platforms = ["x86_64-linux"];
  };
})
