{pkgs, ...}: {
  home.packages = [pkgs.pkgsCuda.blender]; # cycles renders on the gpu through cuda; the cuda variant comes from cache.nixos-cuda.org
}
