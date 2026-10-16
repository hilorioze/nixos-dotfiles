{
  # keep-sorted start
  fetchFromGitHub,
  lib,
  rustPlatform,
  # keep-sorted end
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "deadlocked-relay";

  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "avitran0";
    repo = "deadlocked";

    tag = "v${finalAttrs.version}";
    hash = "sha256-3/oK4sKQvp0LQG3/Z1Pi0lTQn/GJMgg1/R6RH7YNYnw=";
  };

  cargoHash = "sha256-DlfqbMtYz+rw/7Dxyp/AvQXWhodR2vr7Z0nzKGD+iVI=";

  # build only the radar server; the workspace also contains the client
  buildAndTestSubdir = "server";

  meta = {
    description = "Deadlocked web radar relay server";
    homepage = "https://github.com/avitran0/deadlocked";

    license = lib.licenses.gpl3Only;

    mainProgram = "server";

    platforms = ["x86_64-linux"];
  };
})
