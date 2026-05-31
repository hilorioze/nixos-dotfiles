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
      MIIBoDCCAVKgAwIBAgIJAOd1pCBqcknFMAUGAytlcDBKMRIwEAYDVQQKEwlTeW5j
      dGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJhdGVkMRIwEAYDVQQD
      EwlzeW5jdGhpbmcwHhcNMjYwMzA5MDAwMDAwWhcNNDYwMzA0MDAwMDAwWjBKMRIw
      EAYDVQQKEwlTeW5jdGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJh
      dGVkMRIwEAYDVQQDEwlzeW5jdGhpbmcwKjAFBgMrZXADIQBicHmLP2jQ3Tvw3Zmp
      1wvA138HIj6BkgMCQKJNSFaN36NVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQW
      MBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuC
      CXN5bmN0aGluZzAFBgMrZXADQQAyIkMmOwcHYIiX8fZ+Gf+BFZNFaz/Bl0HYiqBB
      Ra8Yq3oSMr1DlTfMWcLioMcPYB1q3gxHe+UzCs4aeIAvGnUA
      -----END CERTIFICATE-----
    ''}";

    settings.folders."Sync" = {
      path = "${config.home.homeDirectory}/Sync";

      devices = [
        # keep-sorted start
        "hilonix"
        "philone"
        # keep-sorted end
      ];
    };
  };
}
