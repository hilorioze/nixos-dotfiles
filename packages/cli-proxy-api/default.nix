{
  # keep-sorted start
  buildGoModule,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildGoModule (finalAttrs: {
  pname = "cli-proxy-api";

  version = "7.2.42";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";

    tag = "v${finalAttrs.version}";
    hash = "sha256-ZaUCRIgKo3NQCXI9tMOwB70zl94n8smOwUXlc1w7EzQ=";
  };

  vendorHash = "sha256-vQU3hLDga5PMUwH4KSB3T5sZ1uPUgHQHeyQGJTKHIYs=";

  # disable broken upstream tests in `management` and `pluginhost`
  doCheck = false;

  meta = {
    description = "API proxy wrapping Gemini CLI, Antigravity, ChatGPT Codex, Claude Code, and Grok Build";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";

    license = lib.licenses.mit;

    mainProgram = "server";

    platforms = ["x86_64-linux"];
  };
})
