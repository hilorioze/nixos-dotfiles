{
  # keep-sorted start
  config,
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko

    ../common

    # keep-sorted start
    ./features
    ./users
    # keep-sorted end
  ];

  disko.devices.disk.main = {
    device = "/dev/sda";

    content = {
      type = "gpt";

      partitions = {
        boot = {
          type = "EF02"; # for grub MBR

          size = "1M";
        };

        swap = {
          size = "4G";

          content = {
            type = "swap";

            discardPolicy = "both";
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
    hostName = "hel0";
    domain = "hilorioze.com";

    interfaces.eth0.ipv6.addresses = [
      {
        address = (lib.importJSON ../servers.json).${config.networking.hostName}.ipv6;
        prefixLength = 64;
      }
    ];

    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };

    nameservers = [
      "2a01:4ff:ff00::add:2"
      "2a01:4ff:ff00::add:1"
    ];
  };

  hardware.facter.reportPath = ./facter.json;

  system.stateVersion = "25.05";

  nixpkgs.hostPlatform.system = "x86_64-linux";
}
