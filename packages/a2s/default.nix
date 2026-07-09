{
  # keep-sorted start
  buildGoModule,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildGoModule (finalAttrs: {
  pname = "a2s";

  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "WoozyMasta";
    repo = "a2s";

    tag = "v${finalAttrs.version}";
    hash = "sha256-p0vy4BXrSR1LgC22pH5bGu5B0W0b/MzQ8lU7XBVctSc=";
  };

  vendorHash = "sha256-Yl1F6444pt/mmnxGjRYafZeY25+OUdbl6WB0Jy9zglw=";

  # build only the cli package; the rest are libraries
  subPackages = ["cmd/a2s"];

  meta = {
    description = "Command-line utility for querying Steam A2S server information";
    homepage = "https://github.com/WoozyMasta/a2s";

    license = lib.licenses.agpl3Only;

    mainProgram = "a2s";

    platforms = ["x86_64-linux"];
  };
})
