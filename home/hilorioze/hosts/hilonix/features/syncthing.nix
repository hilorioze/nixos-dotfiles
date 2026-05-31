{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  services.syncthing = {
    cert = "${pkgs.writeText "syncthing-cert.pem" ''
      -----BEGIN CERTIFICATE-----
      MIIBnzCCAVGgAwIBAgIIF3kTAjgyeacwBQYDK2VwMEoxEjAQBgNVBAoTCVN5bmN0
      aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0ZWQxEjAQBgNVBAMT
      CXN5bmN0aGluZzAeFw0yNjAxMjkwMDAwMDBaFw00NjAxMjQwMDAwMDBaMEoxEjAQ
      BgNVBAoTCVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0
      ZWQxEjAQBgNVBAMTCXN5bmN0aGluZzAqMAUGAytlcAMhAFfZ7lhincm/2rClh9l5
      6YcUj10QTrLgaR8knmk59zx0o1UwUzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYw
      FAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwFAYDVR0RBA0wC4IJ
      c3luY3RoaW5nMAUGAytlcANBAJF/WPjK/NJNiA7CHArIIGgTrD1rLEWR3b+bA4X3
      xFItALF6d8jno44VSXc/ukXuiq+YwIG4KQaFmz3THa/iQAE=
      -----END CERTIFICATE-----
    ''}";

    settings.folders."Sync" = {
      path = "${config.home.homeDirectory}/Sync";

      devices = [
        # keep-sorted start
        "lelonix"
        "philone"
        # keep-sorted end
      ];
    };
  };
}
