{
  # keep-sorted start
  inputs,
  modulesPath,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [
    # keep-sorted start
    "${inputs.nixos-hardware}/common/gpu/nvidia/ampere"
    "${modulesPath}/installer/scan/not-detected.nix"
    # keep-sorted end

    # keep-sorted start
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia # prime
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    # keep-sorted end

    ../common

    # keep-sorted start
    ./features
    ./users
    # keep-sorted end
  ];

  boot = {
    binfmt.emulatedSystems = ["aarch64-linux"];

    loader.efi = {
      efiSysMountPoint = "/efi";

      canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_zen;
  };

  fileSystems = {
    "/efi" = {
      device = "/dev/disk/by-partlabel/EFI";
      fsType = "vfat";
      options = [
        # keep-sorted start
        "noatime"
        "umask=0027"
        # keep-sorted end
      ];
    };

    "/" = {
      device = "/dev/disk/by-partlabel/nixos";
      fsType = "bcachefs";
      options = ["noatime"];
    };

    # `ntfs3` real mount; `bindfs` overlays it at `/mnt/vol` with full access for all users
    "/mnt/.vol" = {
      device = "/dev/disk/by-partlabel/vol";
      fsType = "ntfs3";
      options = [
        # keep-sorted start
        "acl=0" # `ntfs3` unconditionally enables ACL when compiled with `POSIX_ACL`
        "noatime"
        "nofail"
        # keep-sorted end
      ];
    };

    # `bindfs` overlay with full access for all users, ignoring `ntfs3` on-disk WSL EA permissions
    "/mnt/vol" = {
      device = "/mnt/.vol";
      depends = ["/mnt/.vol"];
      fsType = "fuse.bindfs";
      options = [
        # keep-sorted start
        "force-group=root"
        "force-user=root"
        "nofail"
        "perms=0777"
        # keep-sorted end
      ];
    };

    "/mnt/Ventoy" = {
      device = "/dev/disk/by-partlabel/Ventoy";
      fsType = "exfat";
      options = [
        # keep-sorted start
        "noatime"
        "noauto"
        "nofail"
        "umask=0000"
        # keep-sorted end
      ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/swap";
      discardPolicy = "both";
    }
  ];

  networking = {
    hostName = "hilonix";
    domain = "hilorioze.com";
  };

  hardware.nvidia = {
    powerManagement = {
      enable = true; # enable power management through systemd (sleep, hibernation, etc.)

      finegrained = true;
    };

    prime = {
      amdgpuBusId = "PCI:12:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  system.stateVersion = "26.05";

  nixpkgs = {
    config.cudaSupport = true;

    hostPlatform.system = "x86_64-linux";
  };
}
