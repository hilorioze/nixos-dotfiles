{
  # keep-sorted start
  fetchurl,
  lib,
  stdenvNoCC,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "csldr";

  version = "2.31";

  src = fetchurl {
    url = "https://github.com/mikkokko/csldr/releases/download/v${finalAttrs.version}/client.so";

    hash = "sha256-gJJyn0BHew0Zj+YMzlzEf+3MgV6pr38C6pINdnVD65Q=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -D --mode=755 $src $out/lib/client.so

    runHook postInstall
  '';

  meta = {
    description = "Client-side enhancements for CS 1.6 and Condition Zero";
    homepage = "https://github.com/mikkokko/csldr";

    license = lib.licenses.unfree;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];

    platforms = ["i686-linux"];
  };
})
