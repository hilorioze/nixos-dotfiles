{
  # keep-sorted start
  autoPatchelfHook,
  dpkg,
  fetchurl,
  lib,
  nix-update-script,
  openal,
  qt5,
  stdenv,
  # keep-sorted end
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "half-life-asset-manager";

  version = "3.0.0";

  src = fetchurl {
    url = "https://github.com/SamVanheer/HalfLifeAssetManager/releases/download/HLAM-V${finalAttrs.version}/halflifeassetmanager_${finalAttrs.version}_amd64.deb";

    hash = "sha256-pOao67XEQ6uF37d+LRIlgUx80vcBR6EjIMdU6VLUF2I=";
  };

  postPatch = ''
    substituteInPlace usr/share/applications/hlam.desktop \
      --replace-fail 'Exec=hlam %u' 'Exec=${finalAttrs.meta.mainProgram} %f'

    echo 'MimeType=application/x-goldsrc-mdl;' >> usr/share/applications/hlam.desktop
  '';

  strictDeps = true;

  nativeBuildInputs = [
    # keep-sorted start
    autoPatchelfHook
    dpkg
    qt5.wrapQtAppsHook
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    openal
    qt5.qtbase
    stdenv.cc.cc.lib
    # keep-sorted end
  ];

  installPhase = ''
    runHook preInstall

    cp --recursive usr $out

    install -D --mode=644 ${./mimetype.xml} $out/share/mime/packages/hlam.xml

    runHook postInstall
  '';

  # release tags carry a prefix that is not part of the version
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--version-regex=^HLAM-V(.+)$"];
  };

  meta = {
    description = "Tool for viewing and editing Half-Life 1 models";
    homepage = "https://github.com/SamVanheer/HalfLifeAssetManager";

    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];

    mainProgram = "hlam";

    platforms = ["x86_64-linux"];
  };
})
