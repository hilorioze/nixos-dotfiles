{writers}: let
  inherit (import ../../shared.nix) ignoredFlake8Rules;
in
  (writers.writePython3Bin "claude-code-status-line" {
    flakeIgnore = ignoredFlake8Rules;
  } (builtins.readFile ./claude-code-status-line.py)).overrideAttrs (oldAttrs: {
    passthru.skipUpdate = true; # the script lives in this repository

    meta = oldAttrs.meta // {platforms = ["x86_64-linux"];};
  })
