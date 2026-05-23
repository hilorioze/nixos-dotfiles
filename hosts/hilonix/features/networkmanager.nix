{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/networkmanager.nix];

  sops = {
    secrets."infra/wireguard/interfaces/warp/private-key" = {};
    templates."infra/wireguard/interfaces/warp.env".content = ''
      WARP_WG_PRIVATE_KEY=${config.sops.placeholder."infra/wireguard/interfaces/warp/private-key"}
    '';
  };

  networking.networkmanager = {
    ensureProfiles = {
      environmentFiles = [config.sops.templates."infra/wireguard/interfaces/warp.env".path];

      profiles.warp = {
        connection = {
          id = "warp";
          interface-name = "warp";
          type = "wireguard";
          autoconnect = false;
        };
        ipv4 = {
          address1 = "172.16.0.2/32";
          dns = "1.1.1.1;1.0.0.1;";
          dns-search = "~;";
          method = "manual";
        };
        ipv6 = {
          addr-gen-mode = "default";
          address1 = "2606:4700:110:804e:1920:9926:d762:ad8a/128";
          dns = "2606:4700:4700::1111;2606:4700:4700::1001;";
          dns-search = "~;";
          method = "manual";
        };
        wireguard = {
          mtu = 1280;
          private-key = "$WARP_WG_PRIVATE_KEY";
        };
        "wireguard-peer.bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=" = {
          allowed-ips = "0.0.0.0/0;::/0;";
          endpoint = "engage.cloudflareclient.com:2408";
        };
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
