{pkgs, ...}: {
  virtualisation = {
    libvirtd = {
      enable = true;

      qemu.vhostUserPackages = [pkgs.virtiofsd];
    };

    spiceUSBRedirection.enable = true;
  };
}
