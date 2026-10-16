{
  # make rapl energy files readable for mangohud cpu power display
  systemd.tmpfiles.rules = [
    "z /sys/class/powercap/intel-rapl*/energy_uj 0444 root root -"
  ];
}
