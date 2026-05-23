{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko

    ../common

    # keep-sorted start
    ./features
    ./users
    # keep-sorted end
  ];

  boot.loader.efi.efiSysMountPoint = "/efi";

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
    hostName = "fakesynology-nixos";
    domain = "hilorioze.com";
  };

  hardware.facter.reportPath = ./facter.json;
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
