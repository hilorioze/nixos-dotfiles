final: prev: {
  unstablePkgs = prev.unstablePkgs.extend (_unstableFinal: unstablePrev: {
    # playwright enables the cdp `Runtime` domain on every page, which anti-bot scripts detect; link patchright, a `playwright-core` fork without it
    playwright-mcp = unstablePrev.playwright-mcp.overrideAttrs (oldAttrs: {
      postInstall =
        oldAttrs.postInstall
        + ''
          ln --symbolic --force --no-target-directory ${final.patchright-core} $pkg_dir/node_modules/playwright-core
        '';
    });
  });
}
