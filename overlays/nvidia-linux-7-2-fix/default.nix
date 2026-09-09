final: prev: {
  kernelPackagesExtensions =
    prev.kernelPackagesExtensions
    ++ [
      (_finalKernelPackages: prevKernelPackages: {
        nvidiaPackages =
          prevKernelPackages.nvidiaPackages
          // {
            stable =
              prevKernelPackages.nvidiaPackages.stable
              // {
                open = prevKernelPackages.nvidiaPackages.stable.open.overrideAttrs (oldAttrs: {
                  patches =
                    (oldAttrs.patches or [])
                    ++ [
                      (final.fetchurl {
                        url = "https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/94bcd86886298f7798837a38dc1ff361d60a9c8d/nvidia/nvidia-utils/0001-make-Add-support-for-7.2-Kernel.patch";

                        hash = "sha256-hdklzeaY0s/0RME+CtQoddwOuTkSh+/jNdDD6t7cC48=";
                      })
                    ];
                });
              };
          };
      })
    ];
}
