{
  # keep-sorted start
  cmake,
  copyDesktopItems,
  fetchFromGitHub,
  glew,
  glfw,
  lib,
  libGLU,
  libx11,
  libxi,
  libxrandr,
  libxxf86vm,
  makeDesktopItem,
  stdenv,
  # keep-sorted end
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "bspguy";

  version = "6";

  src = fetchFromGitHub {
    owner = "wootguy";
    repo = "bspguy";

    tag = "v${finalAttrs.version}";
    hash = "sha256-NhkxnQ9SqddPgJZXqGjT/R6I+lhsJhFdtmHAF6fvlyc=";

    fetchSubmodules = true;
  };

  strictDeps = true;

  nativeBuildInputs = [
    # keep-sorted start
    cmake
    copyDesktopItems
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    glew
    glfw
    libGLU
    libx11
    libxi
    libxrandr
    libxxf86vm
    # keep-sorted end
  ];

  hardeningDisable = ["format"];

  desktopItems = [
    (makeDesktopItem {
      name = "bspguy";

      desktopName = "bspguy";
      icon = "bspguy";

      exec = "bspguy %f";

      mimeTypes = ["application/x-goldsrc-bsp"];

      categories = ["Development"];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -D --mode=755 bspguy $out/bin/bspguy

    install -D --mode=644 $src/src/data/icons/app.png $out/share/icons/hicolor/64x64/apps/bspguy.png

    install -D --mode=644 ${./mimetype.xml} $out/share/mime/packages/bspguy.xml

    runHook postInstall
  '';

  meta = {
    description = "Tool for editing GoldSrc maps without decompiling";
    homepage = "https://github.com/wootguy/bspguy";

    license = lib.licenses.unlicense;

    mainProgram = "bspguy";

    platforms = ["x86_64-linux"];
  };
})
