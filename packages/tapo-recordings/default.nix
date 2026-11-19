{
  # keep-sorted start
  ffmpeg-headless,
  lib,
  python3Packages,
  writers,
  # keep-sorted end
}:
(writers.writePython3Bin "tapo-recordings" {
  libraries = [
    # keep-sorted start
    python3Packages.firebase-messaging
    python3Packages.pytapo
    # keep-sorted end
  ];

  makeWrapperArgs = ["--prefix PATH : ${lib.makeBinPath [ffmpeg-headless]}"]; # pytapo's downloader runs `ffmpeg` and `ffprobe` from `PATH`

  doCheck = false; # treefmt lints the script with ruff
} (builtins.replaceStrings ["@cloudCa@"] ["${./cloud-ca.pem}"] (builtins.readFile ./tapo-recordings.py))).overrideAttrs (oldAttrs: {
  passthru.skipUpdate = true; # the script lives in this repository

  meta = oldAttrs.meta // {platforms = ["x86_64-linux"];};
})
