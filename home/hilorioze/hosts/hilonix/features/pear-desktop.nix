{pkgs, ...}: {
  home.packages = [
    (pkgs.pear-desktop.overrideAttrs (oldAttrs: {
      postFixup =
        oldAttrs.postFixup
        + ''
          wrapProgram $out/bin/pear-desktop \
            --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
            --set VK_DRIVER_FILES ${pkgs.mesa}/share/vulkan/icd.d/radeon_icd.x86_64.json
        '';
    }))
  ];
}
