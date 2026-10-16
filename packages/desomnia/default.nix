{
  # keep-sorted start
  buildDotnetModule,
  clang,
  dotnetCorePackages,
  fetchFromGitHub,
  lib,
  libpcap,
  # keep-sorted end
}:
buildDotnetModule (finalAttrs: {
  pname = "desomnia";

  version = "3.3.1";

  src = fetchFromGitHub {
    owner = "mad0x20wizard";
    repo = "Desomnia";

    rev = "v${finalAttrs.version}";
    hash = "sha256-c7bkM1jIKqQBcvXzJkLaOFSwv4EYBefffrjJs/X8sH0=";
  };

  nativeBuildInputs = [clang];

  projectFile = "DesomniaDaemon/DesomniaDaemon.csproj";

  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;

  dotnetFlags = ["-p:PublishAot=true"];

  selfContainedBuild = true;

  executables = [finalAttrs.meta.mainProgram];

  runtimeDeps = [libpcap];

  meta = {
    description = "Background service for Wake-on-LAN and system sleep management with filters and extra monitors";
    homepage = "https://github.com/mad0x20wizard/Desomnia";

    license = lib.licenses.gpl3Only;

    mainProgram = "desomniad";

    platforms = ["x86_64-linux"];
  };
})
