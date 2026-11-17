{
  imports = [
    # keep-sorted start
    ./features
    ./users
    # keep-sorted end
  ];

  boot = {
    initrd = {
      availableKernelModules = ["virtio_scsi"]; # facter, run under ubuntu, lists no module for the disk's virtio-scsi controller

      systemd.enable = false; # only the scripted initrd moves the old system out of the root on `/etc/NIXOS_LUSTRATE`
    };

    # the server keeps the cloud image's partitions: it lacks the memory to boot an installer through kexec
    loader.grub.device = "/dev/sda";
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";

      fsType = "ext4";

      options = ["noatime"];
    };

    "/" = {
      device = "/dev/disk/by-label/cloudimg-rootfs";

      fsType = "ext4";

      options = ["noatime"];
    };
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";

      size = 1024;
    }
  ];

  networking.hostName = "honeypot";

  hardware.facter.reportPath = ./facter.json;

  system.stateVersion = "26.05";

  nixpkgs.hostPlatform.system = "x86_64-linux";
}
