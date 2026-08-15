{
  # keep-sorted start
  fetchFromGitLab,
  lib,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "plasmavantage";

  version = "0.31";

  src = fetchFromGitLab {
    owner = "Scias";
    repo = "plasmavantage";

    tag = finalAttrs.version;
    hash = "sha256-SUsPb7NblnTpcju1d1km5877IPnaykiKd1bHJ/D6wyw=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    plasmoids_dir=$out/share/plasma/plasmoids

    mkdir --parents $plasmoids_dir
    cp --recursive package $plasmoids_dir/com.gitlab.scias.plasmavantage

    runHook postInstall
  '';

  meta = {
    description = "Plasmoid for KDE Plasma 6 for controlling certain features of Lenovo laptops";

    homepage = "https://gitlab.com/Scias/plasmavantage";

    license = lib.licenses.mpl20;

    platforms = ["x86_64-linux"];
  };
})
