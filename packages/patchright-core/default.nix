{
  # keep-sorted start
  fetchzip,
  lib,
  nix-update-script,
  # keep-sorted end
}:
fetchzip (finalAttrs: {
  pname = "patchright-core";

  version = "1.64.3";

  url = "https://registry.npmjs.org/patchright-core/-/patchright-core-${finalAttrs.version}.tgz";

  hash = "sha256-KF7TDJ4RuX/yfUAvK8ZYf2Wsd8tlq4V1MUquN5Q5wV8=";

  # the package is the fetcher itself, which has no `src` for nix-update to find releases from
  passthru.updateScript.command = nix-update-script {
    extraArgs = ["--url=https://registry.npmjs.org/patchright-core"];
  };

  meta = {
    description = "Undetected version of the Playwright testing and automation library";
    homepage = "https://github.com/Kaliiiiiiiiii-Vinyzu/patchright";

    license = lib.licenses.asl20;

    platforms = ["x86_64-linux"];
  };
})
