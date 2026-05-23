{
  # keep-sorted start
  fetchFromGitHub,
  lib,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "thermalmonitor";

  version = "0.2.7";

  src = fetchFromGitHub {
    owner = "olib14";
    repo = "thermalmonitor";

    tag = "v${finalAttrs.version}";
    hash = "sha256-1TaeE9nsivkaiaCA8lTqwS3DGxh4MlsX1D5Y3VaU584=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/plasma/plasmoids
    cp -r package $out/share/plasma/plasmoids/org.kde.olib.thermalmonitor

    runHook postInstall
  '';

  meta = {
    description = "KDE Plasmoid for showing system temperatures";
    homepage = "https://github.com/olib14/thermalmonitor";

    license = lib.licenses.mit;

    platforms = lib.platforms.linux;
  };
})
