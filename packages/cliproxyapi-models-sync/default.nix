{
  # keep-sorted start
  cliproxyapi-accounts,
  writers,
  # keep-sorted end
}:
(writers.writePython3Bin "cliproxyapi-models-sync" {
  libraries = [cliproxyapi-accounts];

  doCheck = false; # treefmt lints the script with ruff
} (builtins.readFile ./cliproxyapi-models-sync.py)).overrideAttrs (oldAttrs: {
  passthru.skipUpdate = true; # the script lives in this repository

  meta =
    oldAttrs.meta
    // {
      platforms = ["aarch64-linux"];
    };
})
