{
  # keep-sorted start
  fetchFromGitHub,
  lib,
  rustPlatform,
  # keep-sorted end
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "steam-broker";

  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "steam-broker";

    tag = "v${finalAttrs.version}";
    hash = "sha256-1As+JjTbes7zucmuXZot2a/sM2dS3amlxbJopczmILE=";
  };

  cargoHash = "sha256-UQluItgqpvcVLZNiw97tZD4Vh49Xxr5Mt8EmLrWwWCY=";

  postInstall = ''
    install -D \
      target/*/release/build/steamworks-sys-*/out/libsteam_api.so \
      $out/lib/steam-broker/libsteam_api.so
  '';

  meta = {
    description = "Program that communicates with Steam on behalf of others";
    homepage = "https://github.com/FWGS/steam-broker";

    license = lib.licenses.unfree;

    mainProgram = "steam-broker";

    platforms = ["x86_64-linux"];
  };
})
