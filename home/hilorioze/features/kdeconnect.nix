{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: let
  philoneDeviceId = "8ec3da686ba7482e8293aab87f5a4778";
in {
  imports = [../../common/features/kdeconnect.nix];

  sops.secrets."apps/kdeconnect/private-key".path = "${config.xdg.configHome}/kdeconnect/privateKey.pem";

  services.kdeconnect.trustedDevices.${philoneDeviceId} = {
    type = "phone";

    name = "philone";

    protocolVersion = 8;

    # keep the PEM readable here, but store it as a single INI value; `QSettings` decodes `\n` on read
    certificate = builtins.replaceStrings ["\n"] ["\\n"] ''
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

  xdg.configFile = {
    "kdeconnect/config".source = (pkgs.formats.ini {}).generate "kdeconnect-config.ini" {
      General.keyAlgorithm = "EC";
    };

    "kdeconnect/trusted_devices".source = (pkgs.formats.ini {}).generate "kdeconnect-trusted_devices.ini" config.services.kdeconnect.trustedDevices;

    "kdeconnect/${philoneDeviceId}/config".source = (pkgs.formats.ini {}).generate "kdeconnect-philone-config.ini" {
      Plugins = {
        kdeconnect_mpriscontrolEnabled = false;
        kdeconnect_mprisremoteEnabled = false;
      };
    };
  };
}
