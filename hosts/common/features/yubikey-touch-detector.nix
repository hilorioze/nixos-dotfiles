{
  # the openpgp card asks for a touch on every decryption and only blinks meanwhile; works with any card behind gpg-agent, not only yubikeys
  programs.yubikey-touch-detector = {
    enable = true;

    libnotify = true;
  };
}
