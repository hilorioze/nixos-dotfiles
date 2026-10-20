{
  # keep-sorted start
  inputs,
  modulesPath,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"

    inputs.nixos-hardware.nixosModules.lenovo-legion-16iah7h

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

    kernelPackages = pkgs.unstablePkgs.linuxPackages_xanmod_latest; # 26.05's nvidia driver doesn't build against linux 7.2; unstable's does, and the cache has it built for unstable's kernel
    bcachefs.package = pkgs.unstablePkgs.bcachefs-tools; # the module is built from these tools; unstable's give the one the cache has for that kernel

    kernel.sysctl."net.core.default_qdisc" = "fq";
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

    "/mnt/vol" = {
      device = "/dev/disk/by-partlabel/vol";
      fsType = "ntfs-3g"; # never use `ntfs3` here; it honors wsl `$LX*` extended attributes and breaks shared access
      options = [
        # ntfs-3g mounts world-accessible by default; no additional access-control options needed
        # keep-sorted start
        "big_writes"
        "noatime"
        "nofail"
        "windows_names"
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
    hostName = "lelonix";
    domain = "hilorioze.com";
  };

  hardware.nvidia.dynamicBoost.enable = true;

  system.stateVersion = "25.11";

  nixpkgs.hostPlatform.system = "x86_64-linux";
}
