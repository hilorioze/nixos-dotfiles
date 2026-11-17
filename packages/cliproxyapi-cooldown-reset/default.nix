{
  # keep-sorted start
  cliproxyapi-accounts,
  python3Packages,
  writers,
  # keep-sorted end
}:
(writers.writePython3Bin "cliproxyapi-cooldown-reset" {
  libraries = [
    # keep-sorted start
    cliproxyapi-accounts
    python3Packages.aiohttp
    # keep-sorted end
  ];

  doCheck = false; # treefmt lints the script with ruff
} (builtins.readFile ./cliproxyapi-cooldown-reset.py)).overrideAttrs (oldAttrs: {
  passthru.skipUpdate = true; # the script lives in this repository

  meta =
    oldAttrs.meta
    // {
      platforms = ["aarch64-linux"];
    };
})
