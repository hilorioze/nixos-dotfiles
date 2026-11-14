{pkgs, ...}: {
  # ark creates rar archives with `rar` and extracts them with `unrar`, libarchive can't extract solid ones
  home.packages = [pkgs.rar];
}
