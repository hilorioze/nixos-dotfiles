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

    kernelPackages = pkgs.linuxPackages_xanmod_latest;

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
      fsType = "ntfs3";
      options = [
        # keep-sorted start
        "acl=0" # ntfs3 unconditionally enables ACL when compiled with POSIX_ACL
        "dmask=000"
        "fmask=000"
        "gid=0"
        "iocharset=utf8"
        "noatime"
        "nofail"
        "uid=0"
        "umask=000"
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

  nixpkgs = {
    config.cudaSupport = true;

    hostPlatform.system = "x86_64-linux";
  };
}
