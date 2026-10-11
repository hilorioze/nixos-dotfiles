{pkgs, ...}: {
  # restrict the overlay and the recorder it spawns to use the host GPU
  programs.gpu-screen-recorder.ui.package = pkgs.unstablePkgs.gpu-screen-recorder-ui.overrideAttrs (oldAttrs: {
    postInstall =
      oldAttrs.postInstall
      + ''
        wrapProgram $out/bin/${oldAttrs.meta.mainProgram} \
          --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
          --set VK_DRIVER_FILES ${pkgs.mesa}/share/vulkan/icd.d/radeon_icd.x86_64.json
      '';
  });
}
