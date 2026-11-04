{pkgs, ...}: {
  services.syncthing.tray = {
    enable = true;

    package = pkgs.syncthingtray; # `syncthingtray-minimal` is way too minimal
  };
}
