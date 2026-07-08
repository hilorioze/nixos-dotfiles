{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/networkmanager.nix];

  sops = {
    secrets."credentials/wireguard/interfaces/warp/private-key" = {};

    templates."config/networkmanager.env".content = "WARP_WG_PRIVATE_KEY=${config.sops.placeholder."credentials/wireguard/interfaces/warp/private-key"}";
  };

  networking.networkmanager = {
    ensureProfiles = {
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

            autoconnect = false;
          };

          wifi.ssid = "Redmi";
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

    dispatcherScripts = [
      {
        type = "pre-up";

        source = pkgs.writeShellScript "nm-cloudflare-ddns.sh" ''
          case "$NM_DISPATCHER_ACTION" in
            dhcp4-change|dhcp6-change|up)
              systemctl start cloudflare-ddns.service
              ;;
          esac
        '';
      }
    ];
  };
}
