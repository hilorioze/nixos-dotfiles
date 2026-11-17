{
  # keep-sorted start
  claude-code-quotas,
  writers,
  # keep-sorted end
}:
(writers.writePython3Bin "claude-code-status-line" {
  libraries = [claude-code-quotas];

  doCheck = false; # treefmt lints the script with ruff
} (builtins.readFile ./claude-code-status-line.py)).overrideAttrs (oldAttrs: {
  passthru.skipUpdate = true; # the script lives in this repository

  meta = oldAttrs.meta // {platforms = ["x86_64-linux"];};
})
