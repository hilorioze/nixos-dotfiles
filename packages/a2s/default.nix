{
  # keep-sorted start
  buildGoModule,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildGoModule (finalAttrs: {
  pname = "a2s";

  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "WoozyMasta";
    repo = "a2s";

    tag = "v${finalAttrs.version}";
    hash = "sha256-Mh1hcp1efM3a+T2IWxz+q29AovwKVQdTNxzUQ93RFD8=";
  };

  vendorHash = "sha256-EuFKcbzcSvgfZJJxLhe04LMC2CGF7AeoNkHXBA6/bIc=";

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
