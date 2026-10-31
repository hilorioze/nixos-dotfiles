{
  # keep-sorted start
  claude-code-quotas,
  cliproxyapi-accounts,
  python3Packages,
  writers,
  # keep-sorted end
}:
(writers.writePython3Bin "claude-code-gateway" {
  libraries = [
    # keep-sorted start
    claude-code-quotas
    cliproxyapi-accounts
    python3Packages.aiohttp
    # keep-sorted end
  ];

  flakeIgnore = (import ../../shared.nix).ignoredFlake8Rules;
} (builtins.readFile ./claude-code-gateway.py)).overrideAttrs (oldAttrs: {
  passthru.skipUpdate = true; # the script lives in this repository

  meta =
    oldAttrs.meta
    // {
      platforms = [
        # keep-sorted start
        "aarch64-linux"
        "x86_64-linux"
        # keep-sorted end
      ];
    };
})
