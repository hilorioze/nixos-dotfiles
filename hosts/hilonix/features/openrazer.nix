{
  imports = [
    # keep-sorted start
    ../../common/features/openrazer.nix
    # keep-sorted end
  ];

  hardware.openrazer.devicesOffOnScreensaver = false;
}
