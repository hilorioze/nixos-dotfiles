{pkgs, ...}: {
  services.wivrn = {
    enable = true;

    package = pkgs.wivrn.override {cudaSupport = true;}; # nvenc encoding; needs only the driver at runtime, not the cuda toolkit

    openFirewall = true;

    highPriority = true;

    steam.importOXRRuntimes = true;
  };
}
