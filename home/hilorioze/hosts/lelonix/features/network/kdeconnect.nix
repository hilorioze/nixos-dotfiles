{
  # keep-sorted start
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: let
  hilonixDeviceId = "92df22e5a8e3430293451ba71df38753";
in {
  services.kdeconnect.trustedDevices.${hilonixDeviceId} = {
    type = "desktop";

    name = "hilonix";

    protocolVersion = 8;

    # store it as a single INI value; `QSettings` decodes `\n` on read
    certificate = builtins.replaceStrings ["\n"] ["\\n"] outputs.nixosConfigurations.hilonix.config.home-manager.users.hilorioze.xdg.configFile."kdeconnect/certificate.pem".text;
  };

  xdg.configFile = {
    "kdeconnect/certificate.pem".text = ''
      -----BEGIN CERTIFICATE-----
      MIIBnjCCAUSgAwIBAgIUV6vc6gQnolu3gZBxm05jBbrQ+44wCgYIKoZIzj0EAwQw
      TzEpMCcGA1UEAwwgODk4ZThlOGQzNzU0NGUwYWJjMDRmZTE1OTM5YzQyN2MxDDAK
      BgNVBAoMA0tERTEUMBIGA1UECwwLS0RFIENvbm5lY3QwHhcNMTkwMTAxMDAwMDM4
      WhcNMjkxMjI5MDAwMDM4WjBPMSkwJwYDVQQDDCA4OThlOGU4ZDM3NTQ0ZTBhYmMw
      NGZlMTU5MzljNDI3YzEMMAoGA1UECgwDS0RFMRQwEgYDVQQLDAtLREUgQ29ubmVj
      dDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABMHMnlSEGfQaURxrPoZ0/MRl95Cq
      4dcdKTyUQrpJOZtniVU4hJAi9Ujpw6tQqqIwQhgBUSZ2KN1T8ZeAzQpLDT8wCgYI
      KoZIzj0EAwQDSAAwRQIgTksp1p3dbISL1PlZViq2Z2BotA2m9XC8E/sMIO7rrXEC
      IQCY7rDerR9DJtshkdU12KdmMeH++vuwZAeLwKa8IicIrA==
      -----END CERTIFICATE-----
    '';

    "kdeconnect/${hilonixDeviceId}/config".source = (pkgs.formats.ini {}).generate "kdeconnect-hilonix-config.ini" {
      Plugins = {
        kdeconnect_mpriscontrolEnabled = false;
        kdeconnect_mprisremoteEnabled = false;
      };
    };
  };
}
