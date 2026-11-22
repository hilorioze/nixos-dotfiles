{
  # keep-sorted start
  coreutils,
  curl,
  writeShellApplication,
  # keep-sorted end
}:
writeShellApplication {
  name = "cookie-browser-fetch";

  runtimeInputs = [
    # keep-sorted start
    coreutils
    curl
    # keep-sorted end
  ];

  excludeShellChecks = (import ../../shared.nix).ignoredShellcheckRules;

  # `cookie-browser-fetch <cookies.txt> <curlrc> <host>...`: take the cookies from the first cookie browser that answers; each keeps its own logins
  text = ''
    output=$1
    config=$2
    shift 2

    for host; do
      if curl --config=$config --fail --silent --show-error --output=$output.new https://cookies.$host; then
        mv $output.new $output # replace the file at once, so a download never reads it half written

        exit 0
      fi
    done

    exit 1
  '';

  passthru.skipUpdate = true; # the script lives in this repository
}
