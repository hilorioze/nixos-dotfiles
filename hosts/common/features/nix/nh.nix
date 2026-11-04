{
  programs.nh.clean = {
    enable = true;

    extraArgs = "--keep-since 3d"; # recent generations share most of the store; older ones pin a whole nixpkgs revision
  };

  systemd.services.nh-clean.serviceConfig.CPUSchedulingPolicy = "idle"; # yield the cpu to everything else
}
