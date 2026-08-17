{
  # keep-sorted start
  cmake,
  fetchFromGitHub,
  lib,
  nix-update-script,
  stdenv,
  # keep-sorted end
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libnyquist";

  version = "0-unstable-2026-03-28";

  src = fetchFromGitHub {
    owner = "ddiakopoulos";
    repo = "libnyquist";

    rev = "2e47815ed53b3c042959d088b760ee525699aa66";
    hash = "sha256-chsyHIGl5IFapM2Oo84QPOxdbzx5xSRTEs7AzUdxFZ0=";
  };

  strictDeps = true;

  nativeBuildInputs = [cmake];

  cmakeFlags = [
    (lib.cmakeBool "LIBNYQUIST_BUILD_EXAMPLE" false)
  ];

  postInstall = ''
    cp --recursive ${finalAttrs.src}/include $out/
  '';

  passthru.updateScript = {
    command = nix-update-script {
      extraArgs = ["--version=branch"];
    };

    usePackageEnvironment = false;
  };

  meta = {
    description = "Cross-platform C++11 library for decoding audio";
    homepage = "https://github.com/ddiakopoulos/libnyquist";

    license = lib.licenses.bsd2;

    platforms = ["x86_64-linux"];
  };
})
