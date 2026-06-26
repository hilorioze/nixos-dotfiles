{
  # keep-sorted start
  alsa-lib,
  android-tools,
  copyDesktopItems,
  fetchFromGitHub,
  ffmpeg,
  flutter,
  lib,
  libass,
  libplacebo,
  makeDesktopItem,
  mimalloc,
  mpv-unwrapped,
  p7zip,
  protobuf,
  rinf_cli,
  rustPlatform,
  stdenvNoCC,
  writeText,
  # keep-sorted end
}: let
  pname = "yaas";

  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "skrimix";
    repo = "yaas";

    rev = "b3907b25588b900fb7a6f43f40000cc06bad6bf6";
    hash = "sha256-ir33vhDRvW0TrDFiGeeQFrfcm45Q7xG0BWf+Y8cp4ZU=";
  };

  rustDep = rustPlatform.buildRustPackage {
    inherit pname;

    inherit version;

    inherit src;

    buildAndTestSubdir = "native/hub";

    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        # keep-sorted start
        "apk-info-1.0.11" = "sha256-gG8MYskod9M5/k+oeVEbuvVdpghcea0OVCBR5XTMbtg=";
        "forensic-adb-1.0.0" = "sha256-NwNxPaXSIF7b6A7A64RIjkSUdAISDTlbxkVv7tp34Vw=";
        "sysproxy-0.3.0" = "sha256-2xv1vjthD3J/SFhbnh21bi2V4fcvoo6CpjJDxpSbwnk=";
        # keep-sorted end
      };
    };

    doCheck = false;

    postInstall = ''
      moveToOutput "lib/libhub.so" "$out"
    '';

    passthru.libraryPath = "lib/libhub.so";
  };
in
  flutter.buildFlutterApplication {
    inherit pname;

    inherit version;

    inherit src;

    pubspecLock = lib.importJSON ./pubspec.lock.json;

    customSourceBuilders = {
      rinf = {
        # keep-sorted start
        src,
        version,
        # keep-sorted end
        ...
      }:
        stdenvNoCC.mkDerivation {
          pname = "rinf";

          inherit version;

          inherit src;

          postPatch = let
            fakeCargokitCmake = writeText "FakeCargokit.cmake" ''
              function(apply_cargokit target manifest_dir lib_name any_symbol_name)
                set("''${target}_cargokit_lib" ${rustDep}/${rustDep.passthru.libraryPath} PARENT_SCOPE)
              endfunction()
            '';
          in ''
            cp ${fakeCargokitCmake} cargokit/cmake/cargokit.cmake
          '';

          installPhase = ''
            runHook preInstall

            cp -r . "$out"

            runHook postInstall
          '';

          inherit (src) passthru;
        };

      media_kit_libs_linux = {
        # keep-sorted start
        src,
        version,
        # keep-sorted end
        ...
      }:
        stdenvNoCC.mkDerivation {
          pname = "media_kit_libs_linux";

          inherit version;
          inherit src;

          dontBuild = true;

          postPatch = ''
            pushd ${src.passthru.packageRoot}
            sed -i '/if(MIMALLOC_USE_STATIC_LIBS)/,/unset(MIMALLOC_USE_STATIC_LIBS CACHE)/c\set(MIMALLOC_LIB "${lib.getLib mimalloc}/lib/mimalloc.o" CACHE INTERNAL "")' linux/CMakeLists.txt
            popd
          '';

          installPhase = ''
            runHook preInstall

            cp -r . $out

            runHook postInstall
          '';

          inherit (src) passthru;
        };

      media_kit_video = {
        # keep-sorted start
        src,
        version,
        # keep-sorted end
        ...
      }:
        stdenvNoCC.mkDerivation {
          pname = "media_kit_video";

          inherit version;

          inherit src;

          dontBuild = true;

          postPatch = ''
            pushd ${src.passthru.packageRoot}
            sed -i '/if(ARCH_NAME STREQUAL "x86_64")/,/if(MEDIA_KIT_LIBS_AVAILABLE)/{ /if(MEDIA_KIT_LIBS_AVAILABLE)/!d; /set(LIBMPV_ZIP_URL/d }' linux/CMakeLists.txt
            sed -i '/if(MEDIA_KIT_LIBS_AVAILABLE)/i \
              set(LIBMPV_UNZIP_DIR "${mpv-unwrapped}/lib")\n\
              set(LIBMPV_PATH "${mpv-unwrapped}/lib")\n\
              set(LIBMPV_HEADER_UNZIP_DIR "${mpv-unwrapped.dev}/include/mpv")' linux/CMakeLists.txt
            popd
          '';

          installPhase = ''
            runHook preInstall

            cp -r . $out

            runHook postInstall
          '';

          inherit (src) passthru;
        };
    };

    strictDeps = true;

    buildInputs = [
      # keep-sorted start
      alsa-lib
      ffmpeg
      libass
      libplacebo
      mpv-unwrapped
      # keep-sorted end
    ];

    nativeBuildInputs = [
      # keep-sorted start
      copyDesktopItems
      protobuf
      rinf_cli
      # keep-sorted end
    ];

    preBuild = ''
      ${lib.getExe rinf_cli} gen
    '';

    postInstall = ''
      install -Dm644 ${src}/assets/png/app_icon.png $out/share/icons/hicolor/512x512/apps/yaas.png

      # rinf expects its Rust symbols to be visible to the process on Linux
      patchelf --add-needed libhub.so $out/app/${pname}/yaas
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "yaas";
        desktopName = "YAAS";
        genericName = "Meta Quest sideloader";
        exec = "yaas";
        icon = "yaas";
        categories = ["Utility"];
      })
    ];

    extraWrapProgramArgs = "--prefix PATH : ${lib.makeBinPath [
      # keep-sorted start
      android-tools
      p7zip
      # keep-sorted end
    ]}";

    meta = {
      description = "Cross-platform desktop app for sideloading and managing Meta Quest headsets";
      homepage = "https://github.com/skrimix/yaas";

      license = lib.licenses.mit;

      mainProgram = "yaas";

      platforms = ["x86_64-linux"];
    };
  }
