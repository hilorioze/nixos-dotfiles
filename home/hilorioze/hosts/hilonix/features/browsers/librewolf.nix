{pkgs, ...}: {
  programs.librewolf.package = pkgs.librewolf.overrideAttrs (oldAttrs: {
    makeWrapperArgs =
      (oldAttrs.makeWrapperArgs or [])
      ++ [
        "--set"
        "MOZ_DRM_DEVICE"
        "/dev/dri/by-path/pci-0000:0c:00.0-render"

        "--set"
        "__EGL_VENDOR_LIBRARY_FILENAMES"
        "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
      ];
  });
}
