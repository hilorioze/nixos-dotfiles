{
  # the openpgp card asks for a touch on every decryption and only blinks meanwhile; works with any card behind gpg-agent, not only yubikeys
  programs.yubikey-touch-detector = {
    enable = true;

    libnotify = true;
  };

  # its socket only hands out events, it never starts the detector; a switch that restarts only the socket leaves the detector stopped
  systemd.user.services.yubikey-touch-detector.notSocketActivated = true;
}
