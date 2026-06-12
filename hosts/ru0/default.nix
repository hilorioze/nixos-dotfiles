{inputs, ...}: {
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
    hostName = "ru0";
    domain = "hilorioze.com";

    useDHCP = false;

    interfaces.eth0 = {
      mtu = 1400;

      ipv4.addresses = [
        {
          address = "144.31.222.50";
          prefixLength = 24;
        }
      ];

      ipv6.addresses = [
        {
          address = "2a0c:b641:610::86";
          prefixLength = 128;
        }
      ];
    };

    defaultGateway = {
      interface = "eth0";

      address = "144.31.222.1";
    };

    defaultGateway6 = {
      interface = "eth0";

      address = "2a0c:b641:610::1";
    };

    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
    ];
  };

  hardware.facter.reportPath = ./facter.json;
  system.stateVersion = "26.11";
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
