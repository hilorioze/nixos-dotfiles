{
  # keep-sorted start
  autoPatchelfHook,
  dpkg,
  fetchurl,
  glib-networking,
  gtk3,
  lib,
  stdenv,
  webkitgtk_4_1,
  wrapGAppsHook3,
  # keep-sorted end
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "k1tty-tools";

  version = "2.1.1";

  src = fetchurl {
    url = "https://github.com/quesada-lab/k1tty-tools/releases/download/v${finalAttrs.version}/K1tty.Tools_${finalAttrs.version}_amd64.deb";

    hash = "sha256-8nvvxhJCS67VAmgC/zcvc14jPXFzFbk/HrDHzSdH55c=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    # keep-sorted start
    autoPatchelfHook
    dpkg
    wrapGAppsHook3
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    glib-networking # webkit loads `https` images in messages through it
    gtk3
    stdenv.cc.cc.lib
    webkitgtk_4_1
    # keep-sorted end
  ];

  installPhase = ''
    runHook preInstall

    cp --recursive usr $out

    runHook postInstall
  '';

  meta = {
    description = "Editor and migration tool for local AI coding agent conversation histories";
    homepage = "https://github.com/quesada-lab/k1tty-tools";

    license = lib.licenses.mit;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];

    mainProgram = "k1tty-tools";

    platforms = ["x86_64-linux"];
  };
})
