{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko

    ../common

    # keep-sorted start
    ./features
    ./users
    # keep-sorted end
  ];

  boot = {
    # required for OCI Cloud Shell serial console output
    kernelParams = ["console=ttyS0,9600"];

    loader.efi.efiSysMountPoint = "/efi";
  };

  disko.devices.disk.main = {
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/efi";
            mountOptions = ["noatime"];
          };
        };

        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };

  networking = {
    hostName = "de0";
    domain = "hilorioze.com";
  };

  hardware.facter.reportPath = ./facter.json;
  system.stateVersion = "25.05";
  nixpkgs.hostPlatform.system = "aarch64-linux";
}
