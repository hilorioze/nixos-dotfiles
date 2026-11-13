{
  # keep-sorted start
  python3Packages,
  writers,
  # keep-sorted end
}:
(writers.writePython3Bin "bluetooth-volume-snap" {
  libraries = [python3Packages.dbus-fast];

  flakeIgnore = (import ../../shared.nix).ignoredFlake8Rules;
} (builtins.readFile ./bluetooth-volume-snap.py)).overrideAttrs (oldAttrs: {
  passthru.skipUpdate = true; # the script lives in this repository

  meta = oldAttrs.meta // {platforms = ["x86_64-linux"];};
})
