{
  # keep-sorted start
  aiohttp,
  buildPythonPackage,
  python,
  # keep-sorted end
}:
buildPythonPackage {
  pname = "cliproxyapi-accounts";

  version = "0";

  src = ./.;

  format = "other";

  dependencies = [aiohttp];

  installPhase = ''
    install -D --mode=644 cliproxyapi_accounts.py $out/${python.sitePackages}/cliproxyapi_accounts.py
  '';

  passthru.skipUpdate = true; # the module lives in this repository

  meta.platforms = [
    # keep-sorted start
    "aarch64-linux"
    "x86_64-linux"
    # keep-sorted end
  ];
}
