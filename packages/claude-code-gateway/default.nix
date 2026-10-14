{
  # keep-sorted start
  python3Packages,
  writers,
  # keep-sorted end
}:
(writers.writePython3Bin "claude-code-gateway" {
  libraries = [python3Packages.aiohttp];

  flakeIgnore = (import ../../shared.nix).ignoredFlake8Rules;
} (builtins.readFile ./claude-code-gateway.py)).overrideAttrs (oldAttrs: {
  passthru.skipUpdate = true; # the script lives in this repository

  meta = oldAttrs.meta // {platforms = ["x86_64-linux"];};
})
