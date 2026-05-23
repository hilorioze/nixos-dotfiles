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
    "${inputs.nixos-hardware}/common/gpu/nvidia/ada-lovelace"
    "${modulesPath}/installer/scan/not-detected.nix"
    # keep-sorted end

    # keep-sorted start
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    # keep-sorted end

    ../common

    # keep-sorted start
    ./features
    ./users
    # keep-sorted end

    ./configuration.nix # for editing through `nixos-conf-editor`
  ];

  boot = {
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
  };

  networking = {
    hostName = "zikkkix";
    domain = "hilorioze.com";
  };

  system.stateVersion = "25.11";

  nixpkgs = {
    config.cudaSupport = true;

    hostPlatform.system = "x86_64-linux";
  };
}
