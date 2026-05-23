{config, ...}: {
  sops.secrets."services/wireguard-server/private-key" = {};

  networking = {
    firewall.allowedUDPPorts = [config.networking.wireguard.interfaces.wg.listenPort];

    wireguard.interfaces.wg = {
      listenPort = 51820;

      privateKeyFile = config.sops.secrets."services/wireguard-server/private-key".path;

      ips = ["10.77.0.1/24"];

      peers = [
        {
          name = "hilonix";

          publicKey = "k9AN2XiOHlxDngCg6vTB2NOI5u61qH/jTA+12HHmcC4=";

          allowedIPs = ["10.77.0.10/32"];
        }

        {
          name = "lelonix";

          publicKey = "lIwNjZe7ALjKvjbHR8rSh6SV6o5KzI/5hvpKcYLTuyY=";

          allowedIPs = ["10.77.0.11/32"];
        }

        {
          name = "fakesynology";

          publicKey = "8lECjWZP+CG1js4WPYYdN6WExPlfRKz7MMg7f1A9lwU=";

          allowedIPs = ["10.77.0.12/32"];
        }

        {
          name = "esp32-nat-router";

          publicKey = "qJzcoKQbhwch7iQH+scN6cMcEUDkwFdjj7vlV7n6E1E=";

          allowedIPs = ["10.77.0.13/32"];
        }
      ];
    };
  };
}
