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

    kernelPatches = [
      # https://github.com/NixOS/nixpkgs/issues/521528
      {
        name = "Bluetooth: btmtk: accept too short WMT FUNC_CTRL events";

        patch = pkgs.fetchurl {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/bluetooth/bluetooth-next.git/patch/?id=162b1adeb057d28ad84fd8a03f3c50cf08db5c62";

          hash = "sha256-ij0hQmC0U++AdXWQy6nycnDe6z4yaMoQIrSiLal5DHc=";
        };
      }
    ];

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
