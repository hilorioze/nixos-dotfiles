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

    kernelPackages = pkgs.unstablePkgs.linuxPackages_zen; # 26.05's nvidia driver doesn't build against linux 7.2; unstable's does, and the cache has it built for unstable's kernel
    bcachefs.package = pkgs.unstablePkgs.bcachefs-tools; # the module is built from these tools; unstable's give the one the cache has for that kernel
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
  };

  networking = {
    hostName = "zikkkix";
    domain = "hilorioze.com";
  };

  system.stateVersion = "25.11";

  nixpkgs.hostPlatform.system = "x86_64-linux";
}
