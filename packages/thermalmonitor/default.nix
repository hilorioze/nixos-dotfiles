{
  # keep-sorted start
  fetchFromGitHub,
  lib,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "thermalmonitor";

  version = "0.2.8";

  src = fetchFromGitHub {
    owner = "olib14";
    repo = "thermalmonitor";

    tag = "v${finalAttrs.version}";
    hash = "sha256-RxSy99zr6aObhjEWuWHFb7k6W0BvsLUj6fQCdn+n1Zw=";
  };

  installPhase = ''
    runHook preInstall

    plasmoids_dir=$out/share/plasma/plasmoids

    mkdir --parents $plasmoids_dir
    cp --recursive package $plasmoids_dir/org.kde.olib.thermalmonitor

    runHook postInstall
  '';

  meta = {
    description = "KDE Plasmoid for showing system temperatures";
    homepage = "https://github.com/olib14/thermalmonitor";

    license = lib.licenses.mit;

    platforms = ["x86_64-linux"];
  };
})
