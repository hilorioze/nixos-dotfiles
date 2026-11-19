_final: prev: {
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (python-final: python-prev: {
        pytapo = python-prev.pytapo.overridePythonAttrs (finalAttrs: oldAttrs: {
          version = "3.4.31";

          src = oldAttrs.src.override {
            inherit (finalAttrs) version;
            hash = "sha256-LJtXLFrM18nO3Kvq5PGjaRWQx1jcf7rR77BuPo/j78M=";
          };

          dependencies = oldAttrs.dependencies ++ [python-final.aiofiles]; # the downloader imports it without the package declaring it
        });
      })
    ];
}
