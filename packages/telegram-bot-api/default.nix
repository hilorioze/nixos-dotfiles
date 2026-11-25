{
  # keep-sorted start
  cmake,
  fetchFromGitHub,
  gperf,
  lib,
  nix-update-script,
  openssl,
  stdenv,
  zlib,
  # keep-sorted end
}:
stdenv.mkDerivation {
  pname = "telegram-bot-api";

  version = "0-unstable-2026-11-21";

  src = fetchFromGitHub {
    owner = "tdlib";
    repo = "telegram-bot-api";

    rev = "5df614c91dab8662cfbb24a501ec89949fdcfebb";
    hash = "sha256-QdqUCKBT6BuE2ssMvi58NcMb+m1uzsiGGHynsKDY3wE=";

    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    # keep-sorted start
    cmake
    gperf
    # keep-sorted end
  ];

  buildInputs = [
    # keep-sorted start
    openssl
    zlib
    # keep-sorted end
  ];

  # upstream tags no versions, and aiogram follows each bot api version as it lands on `master`
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--version=branch"];
  };

  meta = {
    description = "Telegram Bot API server";
    homepage = "https://github.com/tdlib/telegram-bot-api";

    license = lib.licenses.boost;

    mainProgram = "telegram-bot-api";

    platforms = ["x86_64-linux"];
  };
}
