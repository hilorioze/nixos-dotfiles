{
  # keep-sorted start
  autoPatchelfHook,
  fetchzip,
  lib,
  libpcap,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "desomnia";

  version = "3.3.1";

  src = fetchzip {
    url = "https://github.com/mad0x20wizard/Desomnia/releases/download/v${finalAttrs.version}/Desomnia_${finalAttrs.version}_linux-x64-native.zip";

    hash = "sha256-fV7nOHGlVokk2lGp3m4htiPdthfssko0dDFWoaHAhqk=";

    stripRoot = false;
  };

  nativeBuildInputs = [autoPatchelfHook];

  runtimeDependencies = [libpcap];

  installPhase = ''
    runHook preInstall

    install -Dm755 desomniad $out/bin/desomniad

    runHook postInstall
  '';

  meta = {
    description = "Background service for Wake-on-LAN and system sleep management with filters and extra monitors";
    homepage = "https://github.com/mad0x20wizard/Desomnia";

    license = lib.licenses.gpl3Only;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];

    mainProgram = "desomniad";

    platforms = ["x86_64-linux"];
  };
})
