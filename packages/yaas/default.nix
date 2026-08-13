{
  # keep-sorted start
  android-tools,
  copyDesktopItems,
  fetchFromGitHub,
  flutter341,
  lib,
  makeDesktopItem,
  mpv-unwrapped,
  nix-update-script,
  p7zip,
  protobuf,
  rinf_cli,
  rustPlatform,
  stdenvNoCC,
  writeText,
  # keep-sorted end
}: let
  pname = "yaas";

  version = "0-unstable-2026-08-08";

  src = fetchFromGitHub {
    owner = "skrimix";
    repo = "yaas";

    rev = "96cc15f7b2e6ca670960d58bfe6ebbba01abf209";
    hash = "sha256-HiIG6zC9TbawhaEFwZEGOlNKqSmxt7Rr/XObI5kwgJM=";
  };

  rustDep = rustPlatform.buildRustPackage {
    inherit pname;

    inherit version;

    inherit src;

    buildAndTestSubdir = "native/hub";

    cargoHash = "sha256-DyKKvxpgN3rp++q/PsdeiRk6HckYQaHE1Z+H/duUosA=";

    doCheck = false;

    passthru.libraryPath = "lib/libhub.so";
  };
in
  flutter341.buildFlutterApplication {
    inherit pname;

    inherit version;

    inherit src;

    autoPubspecLock = "${src}/pubspec.lock";

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
            # avoid `mpv.pc`'s private dependency chain; the plugin only needs headers and `libmpv`
            substituteInPlace linux/CMakeLists.txt \
              --replace-fail "pkg_check_modules(mpv IMPORTED_TARGET mpv)" "
                add_library(PkgConfig::mpv INTERFACE IMPORTED)
                set_target_properties(PkgConfig::mpv PROPERTIES
                  INTERFACE_INCLUDE_DIRECTORIES ${lib.getDev mpv-unwrapped}/include
                  INTERFACE_LINK_LIBRARIES ${lib.getLib mpv-unwrapped}/lib/libmpv.so
                )
                set(mpv_INCLUDE_DIRS ${lib.getDev mpv-unwrapped}/include)
                set(mpv_CFLAGS_OTHER \"\")
              "
          '';

          installPhase = ''
            runHook preInstall

            cp -r . "$out"

            runHook postInstall
          '';

          inherit (src) passthru;
        };
    };

    strictDeps = true;

    nativeBuildInputs = [
      # keep-sorted start
      copyDesktopItems
      protobuf
      rinf_cli
      # keep-sorted end
    ];

    buildInputs = [mpv-unwrapped];

    preBuild = "${lib.getExe rinf_cli} gen";

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

    passthru = {
      # expose the nested rust dependencies so `nix-update` can refresh `cargoHash`
      inherit (rustDep) cargoDeps;

      # upstream only publishes a mutable nightly prerelease; follow `master` instead
      updateScript = {
        command = nix-update-script {
          extraArgs = [
            "--version=branch"
            "--version-regex=^(0-unstable-[0-9-]+)$"
          ];
        };

        # the updater is self-contained and does not need `yaas`'s build environment
        usePackageEnvironment = false;
      };
    };

    meta = {
      description = "Cross-platform desktop app for sideloading and managing Meta Quest headsets";
      homepage = "https://github.com/skrimix/yaas";

      license = lib.licenses.mit;

      mainProgram = "yaas";

      platforms = ["x86_64-linux"];
    };
  }
