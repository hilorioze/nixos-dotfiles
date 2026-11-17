{config, ...}: {
  boot.extraModulePackages = [config.boot.kernelPackages.openrazer];

  # the driver's udev rules give its devices to this group
  users.groups.openrazer = {};

  services.udev.packages = [config.boot.kernelPackages.openrazer];
}
