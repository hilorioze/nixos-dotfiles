{config, ...}: {
  sops = {
    secrets = {
      # keep-sorted start
      "credentials/wifi/Redmi/psk" = {};
      "credentials/wireguard/interfaces/warp/private-key" = {};
      # keep-sorted end
    };

    templates."services/networkmanager.env".content = ''
      # keep-sorted start
      REDMI_PSK=${config.sops.placeholder."credentials/wifi/Redmi/psk"}
      WARP_WG_PRIVATE_KEY=${config.sops.placeholder."credentials/wireguard/interfaces/warp/private-key"}
      # keep-sorted end
    '';
  };

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=IE
  '';

  networking.networkmanager = {
    enable = true;

    wifi.powersave = false; # prevent latency spikes

    ensureProfiles = {
      environmentFiles = [config.sops.templates."services/networkmanager.env".path];

      profiles = {
        # keep-sorted start block=yes newline_separated=yes
        Redmi = {
          connection = {
            type = "wifi";

            id = "Redmi";
          };

          wifi.ssid = "Redmi";

          wifi-security = {
            key-mgmt = "wpa-psk";

            psk = "$REDMI_PSK";
          };
        };

        philone = {
          connection = {
            type = "wifi";

            id = "philone";
          };

          wifi.ssid = "philone";
        };

        warp = {
          connection = {
            type = "wireguard";

            id = "warp";

            interface-name = "warp";

            autoconnect = false;
          };

          ipv4 = {
            method = "manual";

            address1 = "172.16.0.2/32";

            dns = "1.1.1.1;1.0.0.1;";
          };

          ipv6 = {
            method = "manual";

            address1 = "2606:4700:110:804e:1920:9926:d762:ad8a/128";

            dns = "2606:4700:4700::1111;2606:4700:4700::1001;";
          };

          wireguard.private-key = "$WARP_WG_PRIVATE_KEY";

          "wireguard-peer.bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=" = {
            endpoint = "engage.cloudflareclient.com:2408";

            allowed-ips = "0.0.0.0/0;::/0;";

            persistent-keepalive = 25; # keep NAT entries alive during inactivity
          };
        };
        # keep-sorted end
      };
    };
  };
}
