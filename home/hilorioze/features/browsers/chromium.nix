{pkgs, ...}: {
  programs.chromium = {
    enable = true;

    package = pkgs.ungoogled-chromium;

    # ungoogled-chromium never updates extensions from the web store; install the pinned crx files that `update-packages.yaml` keeps current
    extensions =
      map (crx: {
        inherit (crx) id;

        inherit (crx) version;

        crxPath = crx;
      }) [
        # keep-sorted start
        pkgs.chromium-extension-playwright
        pkgs.chromium-extension-synclify
        pkgs.chromium-extension-ublock-origin-lite
        # keep-sorted end
      ];
  };
}
