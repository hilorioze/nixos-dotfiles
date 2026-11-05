_final: prev: {
  unstablePkgs =
    prev.unstablePkgs
    // {
      # playwright enables the cdp `Runtime` domain on every page, which anti-bot scripts detect; link patchright, a `playwright-core` fork without it
      playwright-mcp = prev.unstablePkgs.playwright-mcp.overrideAttrs (oldAttrs: {
        postInstall =
          oldAttrs.postInstall
          + ''
            ln --symbolic --force --no-target-directory ${prev.patchright-core} $pkg_dir/node_modules/playwright-core
          '';
      });
    };
}
