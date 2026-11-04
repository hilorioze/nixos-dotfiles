{
  # keep-sorted start
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: let
  lelonixDeviceId = "898e8e8d37544e0abc04fe15939c427c";
in {
  services.kdeconnect.trustedDevices.${lelonixDeviceId} = {
    type = "laptop";

    name = "lelonix";

    protocolVersion = 8;

    # store it as a single INI value; `QSettings` decodes `\n` on read
    certificate = builtins.replaceStrings ["\n"] ["\\n"] outputs.nixosConfigurations.lelonix.config.home-manager.users.hilorioze.xdg.configFile."kdeconnect/certificate.pem".text;
  };

  xdg.configFile = {
    "kdeconnect/certificate.pem".text = ''
      -----BEGIN CERTIFICATE-----
      MIIBnjCCAUSgAwIBAgIUWGgUtzQCkqZmasaJqHb/pVC1luMwCgYIKoZIzj0EAwQw
      TzEpMCcGA1UEAwwgOTJkZjIyZTVhOGUzNDMwMjkzNDUxYmE3MWRmMzg3NTMxDDAK
      BgNVBAoMA0tERTEUMBIGA1UECwwLS0RFIENvbm5lY3QwHhcNMjUwMTI5MjAzOTUw
      WhcNMzYwMTI3MjAzOTUwWjBPMSkwJwYDVQQDDCA5MmRmMjJlNWE4ZTM0MzAyOTM0
      NTFiYTcxZGYzODc1MzEMMAoGA1UECgwDS0RFMRQwEgYDVQQLDAtLREUgQ29ubmVj
      dDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABHvJAhTjly4mZrXWPoGkUS76E1eb
      nRMD/tqPI7pspv4kZBtZJEjnTpIpra81mGwRiPyzwawjtfDvQeJcEST6ulcwCgYI
      KoZIzj0EAwQDSAAwRQIgfGDNkb9nnPCrLVp2UcRBPD3LvibwDPhuV3Hi/fshCMEC
      IQCdAUtNSu/C9pDciNf8FOKNKp/ZjwxBkx7247obxshkvg==
      -----END CERTIFICATE-----
    '';

    "kdeconnect/${lelonixDeviceId}/config".source = (pkgs.formats.ini {}).generate "kdeconnect-lelonix-config.ini" {
      Plugins = {
        kdeconnect_mpriscontrolEnabled = false;
        kdeconnect_mprisremoteEnabled = false;
      };
    };
  };
}
