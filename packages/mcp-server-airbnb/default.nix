{
  # keep-sorted start
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  nix-update-script,
  # keep-sorted end
}:
buildNpmPackage (finalAttrs: {
  pname = "mcp-server-airbnb";

  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "openbnb-org";
    repo = "mcp-server-airbnb";

    tag = "v${finalAttrs.version}";
    hash = "sha256-nhAL0LGBmDpmIQ4nLc0rzYi7OI2sRW/pMSE+5ScqGXk=";
  };

  npmDepsHash = "sha256-GQKfkuuEAUKqWAUA4o2ag2KWktz1RDTkAxpJzxRQNds=";

  # outside the US `www.airbnb.com` answers with a javascript redirect to the country domain, which the scraper can't follow and reports as a changed page structure
  postPatch = ''
    substituteInPlace index.ts --replace-fail '"https://www.airbnb.com"' '"https://www.airbnb.ie"'
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "MCP server for searching Airbnb listings";
    homepage = "https://github.com/openbnb-org/mcp-server-airbnb";

    license = lib.licenses.mit;

    mainProgram = "mcp-server-airbnb";

    platforms = ["x86_64-linux"];
  };
})
