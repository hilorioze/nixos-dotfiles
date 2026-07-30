{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  sops.secrets."credentials/tailscale/auth-key" = {};

  services.tailscale = {
    enable = true;

    openFirewall = true;

    authKeyFile = config.sops.secrets."credentials/tailscale/auth-key".path;

    extraUpFlags = [
      "--login-server=${inputs.self.nixosConfigurations.hel0.config.services.headscale.settings.server_url}"

      # reset imperatively changed preferences on reauthentication because `tailscale up` requires every non-default value to be set explicitly
      "--reset"
    ];
  };

  # default MTU 1280 is too small for QUIC/HTTP3 handshake packets (https://github.com/tailscale/tailscale/issues/2633); 1400 leaves 80 bytes of margin under the 1500 ethernet limit
  systemd.services.tailscaled.environment.TS_DEBUG_MTU = "1400";
}
