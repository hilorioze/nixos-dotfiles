{
  # keep-sorted start
  alsa-lib,
  at-spi2-atk,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fetchurl,
  glib,
  gtk3,
  lib,
  libgbm,
  libgcc,
  libglvnd,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  makeWrapper,
  nix-update-script,
  nspr,
  nss,
  pango,
  stdenvNoCC,
  systemd,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codeburn-desktop";

  version = "0.9.27";

  src = fetchurl {
    url = "https://github.com/getagentseal/codeburn/releases/download/desktop-v${finalAttrs.version}/codeburn-desktop_${finalAttrs.version}_amd64.deb";

    hash = "sha256-A89rxL+TebEF698+d8jOXBBaRTu5kkSmXd5VLMxS3f8=";
  };

  postPatch = ''
    substituteInPlace usr/share/applications/codeburn.desktop \
      --replace-fail 'Exec=/opt/CodeBurn/codeburn %U' 'Exec=${finalAttrs.meta.mainProgram} %U'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    # keep-sorted start
    autoPatchelfHook
    dpkg
    makeWrapper
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libgcc
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    systemd
    # keep-sorted end
  ];

  installPhase = ''
    runHook preInstall

    mkdir --parents $out/lib
    cp --recursive opt/CodeBurn $out/lib/codeburn-desktop

    cp --recursive usr/share $out/

    # only the 1024x1024 icon is shipped, but KDE's icon loader ignores it
    mkdir --parents $out/share/icons/hicolor/512x512
    mv $out/share/icons/hicolor/1024x1024/apps $out/share/icons/hicolor/512x512/apps
    rmdir $out/share/icons/hicolor/1024x1024

    makeWrapper $out/lib/codeburn-desktop/codeburn $out/bin/${finalAttrs.meta.mainProgram} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libglvnd]} \
      --set CHROME_DEVEL_SANDBOX $out/lib/codeburn-desktop/chrome-sandbox \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

    runHook postInstall
  '';

  # desktop releases are tagged separately from the cli and menubar ones
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--version-regex=^desktop-v(.+)$"];
  };

  meta = {
    description = "Desktop application for tracking AI coding token usage and cost";
    homepage = "https://github.com/getagentseal/codeburn";

    license = lib.licenses.mit;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];

    mainProgram = "codeburn-desktop";

    platforms = ["x86_64-linux"];
  };
})
