{
  # keep-sorted start
  buildPythonPackage,
  python,
  # keep-sorted end
}:
buildPythonPackage {
  pname = "claude-code-quotas";

  version = "0";

  src = ./.;

  format = "other";

  installPhase = ''
    install -D --mode=644 claude_code_quotas.py $out/${python.sitePackages}/claude_code_quotas.py
  '';

  passthru.skipUpdate = true; # the module lives in this repository

  meta.platforms = [
    # keep-sorted start
    "aarch64-linux"
    "x86_64-linux"
    # keep-sorted end
  ];
}
