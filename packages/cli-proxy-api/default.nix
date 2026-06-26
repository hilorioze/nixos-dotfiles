{
  # keep-sorted start
  buildGoModule,
  fetchFromGitHub,
  lib,
  # keep-sorted end
}:
buildGoModule (finalAttrs: {
  pname = "cli-proxy-api";

  version = "7.1.39";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";

    tag = "v${finalAttrs.version}";
    hash = "sha256-DtcTYYVVdyyszVFS/n3an1+qYCSSl/BOnGEtanqhbk4=";
  };

  patches = [./fix-session-id-header-case.patch];

  vendorHash = "sha256-AIue9XBsfsKGClRLB1DCME+36crapnOdQrEICFYG1a0=";

  meta = {
    description = "API proxy wrapping Gemini CLI, Antigravity, ChatGPT Codex, Claude Code, and Grok Build";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";

    license = lib.licenses.mit;

    mainProgram = "server";

    platforms = ["x86_64-linux"];
  };
})
