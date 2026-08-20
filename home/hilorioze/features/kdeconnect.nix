{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: let
  # keep-sorted start
  philoneDeviceId = "3c39d0014de044478492ce9d79f698ae";
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
        MIIBizCCATGgAwIBAgIBATAKBggqhkjOPQQDBDBPMSkwJwYDVQQDDCAzYzM5ZDAw
        MTRkZTA0NDQ3ODQ5MmNlOWQ3OWY2OThhZTEUMBIGA1UECwwLS0RFIENvbm5lY3Qx
        DDAKBgNVBAoMA0tERTAeFw0yNTA4MTgyMzAwMDBaFw0zNjA4MTgyMzAwMDBaME8x
        KTAnBgNVBAMMIDNjMzlkMDAxNGRlMDQ0NDc4NDkyY2U5ZDc5ZjY5OGFlMRQwEgYD
        VQQLDAtLREUgQ29ubmVjdDEMMAoGA1UECgwDS0RFMFkwEwYHKoZIzj0CAQYIKoZI
        zj0DAQcDQgAEsyfMiHUuoDFkChuGZjQkPq2aguCk8REw1tvG5VPVlpLSVPoUouRm
        TWwqLGb1aOJ9YwOu3kj3tCrqQE0nGkHHszAKBggqhkjOPQQDBANIADBFAiAGRxyD
        rIYgj5xYsrCqrFsg0aP/2zDfCa5fd+LZnYbKsQIhAJ2ZRXl91KVF4MNFtl2TQPXT
        bGNpSnfrVXMCVKwKc4if
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
