{
  nix.gc = {
    automatic = true;
    dates = "weekly"; # `min-free` covers running low on space in between

    options = "--delete-older-than 3d"; # recent generations share most of the store; older ones pin a whole nixpkgs revision
  };

  systemd.services.nix-gc.serviceConfig.CPUSchedulingPolicy = "idle"; # yield the cpu to everything else
}
