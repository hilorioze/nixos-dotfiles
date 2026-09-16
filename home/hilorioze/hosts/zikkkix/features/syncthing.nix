{pkgs, ...}: {
  services.syncthing = {
    cert = "${pkgs.writeText "syncthing-cert.pem" ''
      -----BEGIN CERTIFICATE-----
      MIIBoDCCAVKgAwIBAgIJAItcNDlkWmcSMAUGAytlcDBKMRIwEAYDVQQKEwlTeW5j
      dGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJhdGVkMRIwEAYDVQQD
      EwlzeW5jdGhpbmcwHhcNMjYwOTE2MDAwMDAwWhcNNDYwOTExMDAwMDAwWjBKMRIw
      EAYDVQQKEwlTeW5jdGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJh
      dGVkMRIwEAYDVQQDEwlzeW5jdGhpbmcwKjAFBgMrZXADIQApH3kES8IiK4eUv94n
      eFc/CVnkwmMA9oRtHPelg0LUSKNVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQW
      MBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuC
      CXN5bmN0aGluZzAFBgMrZXADQQAe505Ime//OQjTVOPf7QF0xzvf5V0hLGuKR/Oc
      GemotHunx0fRKol6Zt8ulLUBGZCPX3kyf04FJzhWhcd7Xq0I
      -----END CERTIFICATE-----
    ''}";

    settings.folders.Sync.devices = [
      # keep-sorted start
      "hilonix"
      "lelonix"
      # keep-sorted end
    ];
  };
}
