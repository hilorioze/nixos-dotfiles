{
  # keep-sorted start
  fetchzip,
  lib,
  nix-update-script,
  # keep-sorted end
}:
fetchzip (finalAttrs: {
  pname = "mcpproxy";

  version = "0.75.0";

  url = "https://github.com/smart-mcp-proxy/mcpproxy-go/releases/download/v${finalAttrs.version}/mcpproxy-${finalAttrs.version}-linux-arm64.tar.gz";

  hash = "sha256-KbEgp/tbiAOpOGab/C1I1KsNG7hDjtxU3MVxSpbft6I=";

  # the archive holds only the static binary
  stripRoot = false;
  postFetch = ''
    mkdir $out/bin
    mv $out/mcpproxy $out/bin
  '';

  # the package is the fetcher itself, which has no `src` for nix-update to find releases from
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--url=https://github.com/smart-mcp-proxy/mcpproxy-go"];
  };

  meta = {
    description = "Proxy that puts many MCP servers behind one endpoint with tool discovery and quarantine";
    homepage = "https://github.com/smart-mcp-proxy/mcpproxy-go";

    license = lib.licenses.mit;

    mainProgram = "mcpproxy";

    platforms = ["aarch64-linux"];
  };
})
