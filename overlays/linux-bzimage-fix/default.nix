_final: prev: {
  # kernel build produces `vmlinuz` instead of `bzImage`, leading to "The bootloader cannot find the proper kernel image"
  linuxPackages_zen = prev.linuxPackages_zen.extend (_self: super: {
    kernel = super.kernel.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          if [ -f $out/vmlinuz ] && [ ! -e $out/bzImage ]; then
            ln -s vmlinuz $out/bzImage
          fi
        '';
    });
  });
}
