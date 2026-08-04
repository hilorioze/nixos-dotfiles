{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: let
  # keep-sorted start
  philoneDeviceId = "8ec3da686ba7482e8293aab87f5a4778";
  puestDeviceId = "cc2dd4a39909421a9c516adfe2428e5a";
  # keep-sorted end
in {
  imports = [../../common/features/kdeconnect.nix];

  sops.secrets."apps/kdeconnect/private-key".path = "${config.xdg.configHome}/kdeconnect/privateKey.pem";

  services.kdeconnect.trustedDevices = let
    mkTrustedDevice = {
      # keep-sorted start
      certificate,
      name,
      type,
      # keep-sorted end
    }: {
      inherit type;

      inherit name;

      protocolVersion = 8;

      # keep the PEM readable in the code, but store it as a single INI value; `QSettings` decodes `\n` on read
      certificate = builtins.replaceStrings ["\n"] ["\\n"] certificate;
    };
  in {
    # keep-sorted start block=yes newline_separated=yes
    ${philoneDeviceId} = mkTrustedDevice {
      type = "phone";

      name = "philone";

      certificate = ''
        -----BEGIN CERTIFICATE-----
        MIIBijCCATGgAwIBAgIBATAKBggqhkjOPQQDBDBPMSkwJwYDVQQDDCA4ZWMzZGE2
        ODZiYTc0ODJlODI5M2FhYjg3ZjVhNDc3ODEUMBIGA1UECwwLS0RFIENvbm5lY3Qx
        DDAKBgNVBAoMA0tERTAeFw0yNDA0MjkyMzAwMDBaFw0zNTA0MjkyMzAwMDBaME8x
        KTAnBgNVBAMMIDhlYzNkYTY4NmJhNzQ4MmU4MjkzYWFiODdmNWE0Nzc4MRQwEgYD
        VQQLDAtLREUgQ29ubmVjdDEMMAoGA1UECgwDS0RFMFkwEwYHKoZIzj0CAQYIKoZI
        zj0DAQcDQgAEVZ37yxoSc093WKPPwxGl14uzSf5YIWPxPDOCsUxcPq9lL2nAyf7M
        v2f1PM1me+rmbk+TxwKNbr65E3YEDjyZlzAKBggqhkjOPQQDBANHADBEAiA2TV2j
        IGrjb5NhG3M4Ur/g1IwcPKtyGq87/lkr9seEEQIgWbksw+Rv66/4Dq++fN9NvOhz
        D3S0eA96cL5bskoGubY=
        -----END CERTIFICATE-----
      '';
    };

    ${puestDeviceId} = mkTrustedDevice {
      type = "tablet";

      name = "puest";

      certificate = ''
        -----BEGIN CERTIFICATE-----
        MIIBizCCATGgAwIBAgIBATAKBggqhkjOPQQDBDBPMSkwJwYDVQQDDCBjYzJkZDRh
        Mzk5MDk0MjFhOWM1MTZhZGZlMjQyOGU1YTEUMBIGA1UECwwLS0RFIENvbm5lY3Qx
        DDAKBgNVBAoMA0tERTAeFw0yNTA4MDIyMzAwMDBaFw0zNjA4MDIyMzAwMDBaME8x
        KTAnBgNVBAMMIGNjMmRkNGEzOTkwOTQyMWE5YzUxNmFkZmUyNDI4ZTVhMRQwEgYD
        VQQLDAtLREUgQ29ubmVjdDEMMAoGA1UECgwDS0RFMFkwEwYHKoZIzj0CAQYIKoZI
        zj0DAQcDQgAEHePmG3XFLt2dZ1CCTr79JR2nFf9F8710xfcntuvA4F2gTu6FkqfD
        ZTYFw2etdwz/CkZZnDJt8TQUgbujyS6jrzAKBggqhkjOPQQDBANIADBFAiB1zc96
        2MN99vBQTJUfwyJEwu8IKEAzITWtv2QeTYQj/wIhAOzlUmxC86kSTJowQEBY48NE
        a7T/Oq488BF/NvyMsZ+4
        -----END CERTIFICATE-----
      '';
    };
    # keep-sorted end
  };

  xdg.configFile = {
    "kdeconnect/config".source = (pkgs.formats.ini {}).generate "kdeconnect-config.ini" {
      General.keyAlgorithm = "EC";
    };

    # keep-sorted start block=yes newline_separated=yes
    "kdeconnect/${philoneDeviceId}/config".source = (pkgs.formats.ini {}).generate "kdeconnect-philone-config.ini" {
      Plugins = {
        kdeconnect_mpriscontrolEnabled = false;
        kdeconnect_mprisremoteEnabled = false;
      };
    };

    "kdeconnect/${puestDeviceId}/config".source = (pkgs.formats.ini {}).generate "kdeconnect-puest-config.ini" {
      Plugins = {
        kdeconnect_mpriscontrolEnabled = false;
        kdeconnect_mprisremoteEnabled = false;
      };
    };
    # keep-sorted end
  };
}
