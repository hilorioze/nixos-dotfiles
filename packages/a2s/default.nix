{
  # keep-sorted start
  fetchurl,
  lib,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "a2s";

  version = "0.4.0";

  src = fetchurl {
    url = "https://github.com/WoozyMasta/a2s/releases/download/v${finalAttrs.version}/a2s-linux-amd64";

    hash = "sha256-IrOu9r92GObT+BDjuJQaBXBCD7FIIaHRQbYOxUDSQr4=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -D --mode=755 $src $out/bin/${finalAttrs.meta.mainProgram}

    runHook postInstall
  '';

  meta = {
    description = "Command-line utility for querying Steam A2S server information";
    homepage = "https://github.com/WoozyMasta/a2s";

    license = lib.licenses.agpl3Only;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];

    mainProgram = "a2s";

    platforms = ["x86_64-linux"];
  };
})
