{
  # keep-sorted start
  cmake,
  copyDesktopItems,
  fetchFromGitHub,
  fontconfig,
  git,
  lib,
  makeDesktopItem,
  makeWrapper,
  ninja,
  python3,
  stdenv,
  xash3d-fwgs,
  # keep-sorted end
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cs16-client";

  version = "continuous";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "cs16-client";

    rev = "8ae1ebe2764c016669d381591ea778c7c9e86f51";
    hash = "sha256-1j49QSLm4lhbPo5IFepgphwxbYNlOq3vKOINow2lt9I=";

    fetchSubmodules = true;
  };

  postPatch = ''
    patchShebangs 3rdparty/ReGameDLL_CS/regamedll/version/appversion.sh

    # regamedll looks for the engine's filesystem in the working directory, which is `~/.xash3d` here
    substituteInPlace 3rdparty/ReGameDLL_CS/regamedll/public/FileSystem.h \
      --replace-fail '"filesystem_stdio.so"' '"${xash3d-fwgs}/lib/filesystem_stdio.so"'

    # sources in the store are dated 1970, which `zipfile` refuses without this
    substituteInPlace scripts/pack_extras.py \
      --replace-fail "compression=zipfile.ZIP_STORED" "compression=zipfile.ZIP_STORED, strict_timestamps=False"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    # keep-sorted start
    cmake
    copyDesktopItems
    git
    makeWrapper
    ninja
    python3
    # keep-sorted end
  ];

  buildInputs = [fontconfig];

  # regamedll ignores `GAME_DIR` and always installs into `cstrike/dlls`
  cmakeFlags = [(lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}/share/xash3d")];

  hardeningDisable = ["format"];

  desktopItems = [
    (makeDesktopItem {
      name = "cs16-client";

      desktopName = "CS16Client";
      icon = "cs16-client";

      exec = finalAttrs.meta.mainProgram;

      categories = ["Game"];

      keywords = ["Counter-Strike"];
    })
  ];

  postInstall = ''
    install -D --mode=644 $src/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png $out/share/icons/hicolor/192x192/apps/cs16-client.png

    # `-rodir` replaces the engine's own read-only dir, so keep its `extras.pk3` there
    ln --symbolic ${xash3d-fwgs}/lib/valve/extras.pk3 $out/share/xash3d/extras.pk3

    # explicit libraries so stale copies in `~/.xash3d/cstrike` can't shadow these
    makeWrapper ${lib.getExe xash3d-fwgs} $out/bin/${finalAttrs.meta.mainProgram} \
      --add-flags "-game cstrike -rodir $out/share/xash3d" \
      --add-flags "-clientlib $out/share/xash3d/cstrike/cl_dlls/client_amd64.so" \
      --add-flags "-menulib $out/share/xash3d/cstrike/cl_dlls/menu_amd64.so" \
      --add-flags "-dll $out/share/xash3d/cstrike/dlls/cs_amd64.so"
  '';

  meta = {
    description = "Reverse-engineered Counter-Strike 1.6 client";
    homepage = "https://github.com/FWGS/cs16-client";

    license = lib.licenses.gpl2Plus;

    mainProgram = "cs16-client";

    platforms = ["x86_64-linux"];
  };
})
