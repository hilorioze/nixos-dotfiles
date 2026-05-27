{
  home.file.".ssh/known_hosts" = {
    force = true;

    text = ''
      github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    '';
  };

  programs.ssh = {
    enable = true;

    enableDefaultConfig = false; # its default is already deprecated and home-manager recommends setting it to false

    settings."*".HostKeyAlgorithms = "ssh-ed25519";
  };
}
