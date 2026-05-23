{config, ...}: {
  imports = [../../common/features/networkmanager.nix];

  sops = {
    secrets."credentials/wireguard/interfaces/wg/private-key" = {};

    templates."config/networkmanager.env".content = ''
      WG_PRIVATE_KEY=${config.sops.placeholder."credentials/wireguard/interfaces/wg/private-key"}
    '';
  };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [config.sops.templates."config/networkmanager.env".path];

    profiles = {
      # keep-sorted start block=yes newline_separated=yes
      "Redmi_2.4GHz" = {
        connection = {
          id = "Redmi_2.4GHz";
          type = "wifi";
          autoconnect = false;
        };
        wifi.ssid = "Redmi_2.4GHz";
      };

      Redmi = {
        connection = {
          id = "Redmi";
          type = "wifi";
        };
        wifi.ssid = "Redmi";
      };

      philone = {
        connection = {
          id = "philone";
          type = "wifi";
        };
        wifi.ssid = "philone";
      };

      wg = {
        connection = {
          type = "wireguard";

          id = "wg";
          interface-name = "wg";

          autoconnect = false;
        };

        ipv4 = {
          method = "manual";

          address1 = "10.77.0.11/32";
        };

        wireguard.private-key = "$WG_PRIVATE_KEY";

        "wireguard-peer.JLuTtcLYah/ZzV4VALE/HYHb1FeeZMdalnmZKzuJzjA=" = {
          endpoint = "wg.hilorioze.com:51820";

          allowed-ips = "10.77.0.13/32;192.168.1.197/32;192.168.1.157/32;";

          persistent-keepalive = 25;
        };
      };
      # keep-sorted end
    };
  };
}
