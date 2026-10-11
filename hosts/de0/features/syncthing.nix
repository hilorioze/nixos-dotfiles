{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets."services/syncthing/private-key".owner = config.services.syncthing.user;

  services.syncthing = {
    enable = true;

    cert = "${pkgs.writeText "syncthing-cert.pem" ''
      -----BEGIN CERTIFICATE-----
      MIIBoDCCAVKgAwIBAgIJAOFqBMnS2TIJMAUGAytlcDBKMRIwEAYDVQQKEwlTeW5j
      dGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJhdGVkMRIwEAYDVQQD
      EwlzeW5jdGhpbmcwHhcNMjYxMDEwMDAwMDAwWhcNNDYxMDA1MDAwMDAwWjBKMRIw
      EAYDVQQKEwlTeW5jdGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJh
      dGVkMRIwEAYDVQQDEwlzeW5jdGhpbmcwKjAFBgMrZXADIQAwGUybLh0CgobqwDTL
      pblsoJI/b5lQindvgp4QgLbBQqNVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQW
      MBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuC
      CXN5bmN0aGluZzAFBgMrZXADQQBAU84yOY883whG3VSbNLwU9eG+Yp/WIc7yT2Dp
      swF+bBzmyId6u75ImyvugkX36iPIx4yc3/QobGCyKZR1FjcK
      -----END CERTIFICATE-----
    ''}";
    key = config.sops.secrets."services/syncthing/private-key".path;

    settings = {
      options = {
        urAccepted = -1; # disable usage reporting

        crashReportingEnabled = false;
      };

      devices = {
        # keep-sorted start
        hilonix.id = "GFGZO74-4OYK3ER-NTZYIJN-OLC6GYO-2EVMICU-HKZPQES-SFZMO7A-YDFS6AZ";
        lelonix.id = "JQI5YOS-SSATHW7-2474YVF-JHB32UO-53NLVN2-HCXT7S5-74TI6MT-6HCD7QC";
        philone.id = "VHDWD3D-HFPWFYH-BZZAWGB-F62N6XS-QFND3NG-XZKLAX2-MOEX46X-CUXXIQX";
        zikkkix.id = "WWNU35D-2QFBCXD-OXBY4EF-6SZ4ZNK-F5WD4N4-724I5IV-RDPRWL3-QO7VUQU";
        # keep-sorted end
      };

      # always-on relay between devices; only holds the encrypted data
      folders.sync = {
        type = "receiveencrypted";

        path = "${config.services.syncthing.dataDir}/sync";

        devices = [
          # keep-sorted start
          "hilonix"
          "lelonix"
          "philone"
          "zikkkix"
          # keep-sorted end
        ];
      };
    };
  };
}
