{config, ...}: {
  imports = [../../common/features/networkmanager.nix];

  sops = {
    secrets = {
      "credentials/wifi/TP-Link_DD02/psk" = {};
      "credentials/wifi/ZTE_2D4035/psk" = {};
    };

    templates."config/networkmanager.env".content = ''
      TP_LINK_DD02_PSK=${config.sops.placeholder."credentials/wifi/TP-Link_DD02/psk"}
      ZTE_2D4035=${config.sops.placeholder."credentials/wifi/ZTE_2D4035/psk"}
    '';
  };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [config.sops.templates."config/networkmanager.env".path];

    profiles = {
      # keep-sorted start block=yes newline_separated=yes
      "Redmi_2.4GHz" = {
        connection = {
          type = "wifi";

          id = "Redmi_2.4GHz";

          autoconnect = false;
        };

        wifi.ssid = "Redmi_2.4GHz";
      };

      Redmi = {
        connection = {
          type = "wifi";

          id = "Redmi";
        };

        wifi.ssid = "Redmi";
      };

      TP-Link_DD02 = {
        connection = {
          type = "wifi";

          id = "TP-Link_DD02";

          autoconnect = false;
        };

        wifi.ssid = "TP-Link_DD02";

        wifi-security = {
          key-mgmt = "wpa-psk";

          psk = "$TP_LINK_DD02_PSK";
        };
      };

      TP-Link_DD02_5G = {
        connection = {
          type = "wifi";

          id = "TP-Link_DD02_5G";
        };

        wifi.ssid = "TP-Link_DD02_5G";

        wifi-security = {
          key-mgmt = "wpa-psk";

          psk = "$TP_LINK_DD02_PSK";
        };
      };

      ZTE_2D4035 = {
        connection = {
          type = "wifi";

          id = "ZTE_2D4035";
        };

        wifi.ssid = "ZTE_2D4035";

        wifi-security = {
          key-mgmt = "wpa-psk";

          psk = "$ZTE_2D4035";
        };
      };

      philone = {
        connection = {
          type = "wifi";

          id = "philone";
        };

        wifi.ssid = "philone";
      };
      # keep-sorted end
    };
  };
}
