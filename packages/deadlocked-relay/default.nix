{
  # keep-sorted start
  deadlocked,
  rustPlatform,
  # keep-sorted end
}:
rustPlatform.buildRustPackage {
  pname = "deadlocked-relay";

  inherit (deadlocked) version;

  inherit (deadlocked) src;

  inherit (deadlocked) cargoDeps;

  # build only the radar server; the workspace also contains the client
  buildAndTestSubdir = "server";

  meta = {
    description = "Deadlocked web radar relay server";
    inherit (deadlocked.meta) homepage;

    inherit (deadlocked.meta) license;

    mainProgram = "server";

    platforms = ["x86_64-linux"];
  };
}
