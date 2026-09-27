{
  # keep-sorted start
  buildNpmPackage,
  codeburn,
  copyDesktopItems,
  electron,
  fetchFromGitHub,
  lib,
  libglvnd,
  makeDesktopItem,
  makeWrapper,
  # keep-sorted end
}:
buildNpmPackage (finalAttrs: {
  pname = "codeburn-desktop";

  version = "0.9.25";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";

    tag = "v${finalAttrs.version}";
    hash = "sha256-MVgXl+fN9qZZmXhlgLXTX0toldDM1oH99Mc5bxScu7g=";
  };

  postPatch = ''
    # the wrapper sets `CODEBURN_BIN` to the separate CLI package; skip upstream's CLI bundling hook
    substituteInPlace package.json \
      --replace-fail '"afterPack": "./scripts/after-pack.cjs"' '"afterPack": null'
  '';

  sourceRoot = "source/app";

  npmDepsHash = "sha256-VxU08npbor8Jzz10CqJU5uQihTnhBJucBwGeiFmT2G8=";

  nativeBuildInputs = [
    # keep-sorted start
    copyDesktopItems
    makeWrapper
    # keep-sorted end
  ];

  # `electron-builder` supplies the runtime tree; skip `buildNpmPackage`'s redundant npm install
  dontNpmInstall = true;

  postBuild = ''
    ./node_modules/.bin/electron-builder --linux dir \
      -c.electronDist=${electron.dist}
  '';

  postInstall = ''
    mkdir --parents $out/lib/codeburn-desktop
    cp --recursive release/linux-unpacked/. $out/lib/codeburn-desktop/

    install -D --mode=644 build/icon.png \
      $out/share/icons/hicolor/512x512/apps/codeburn-desktop.png # source is 1024x1024, but KDE's icon loader ignores it

    makeWrapper $out/lib/codeburn-desktop/codeburn $out/bin/codeburn-desktop \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libglvnd]} \
      --set CHROME_DEVEL_SANDBOX $out/lib/codeburn-desktop/chrome-sandbox \
      --set CODEBURN_BIN ${lib.getExe codeburn} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "codeburn-desktop";

      desktopName = "CodeBurn";
      icon = "codeburn-desktop";

      exec = "codeburn-desktop";

      categories = ["Development"];
    })
  ];

  meta = {
    description = "Desktop application for tracking AI coding token usage and cost";
    homepage = "https://github.com/getagentseal/codeburn";

    license = lib.licenses.mit;

    mainProgram = "codeburn-desktop";

    platforms = ["x86_64-linux"];
  };
})
