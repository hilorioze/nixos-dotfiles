{
  # keep-sorted start
  makeWrapper,
  python3Packages,
  symlinkJoin,
  unstablePkgs,
  writers,
  # keep-sorted end
}: let
  inherit (unstablePkgs) playwright-mcp;

  inherit (import ../../shared.nix) ignoredFlake8Rules;

  readExtensionToken = writers.writePython3 "read-extension-token" {
    libraries = [python3Packages.plyvel];

    flakeIgnore = ignoredFlake8Rules;
  } (builtins.readFile ./read-extension-token.py);
in
  symlinkJoin {
    name = "playwright-mcp-with-extension-token";

    inherit (playwright-mcp) version;

    paths = [playwright-mcp];

    nativeBuildInputs = [makeWrapper];

    # the extension generates its token per browser profile, so read it on every start; an empty value falls back to manual approval
    postBuild = ''
      wrapProgram $out/bin/${playwright-mcp.meta.mainProgram} \
        --run 'export PLAYWRIGHT_MCP_EXTENSION_TOKEN=$(${readExtensionToken} "$PLAYWRIGHT_MCP_USER_DATA_DIR")'
    '';

    passthru.skipUpdate = true; # version follows the 'nixpkgs-unstable' input

    inherit (playwright-mcp) meta;
  }
