{
  # Make RAPL energy files readable for MangoHud CPU power display
  systemd.tmpfiles.rules = [
    "z /sys/class/powercap/intel-rapl*/energy_uj 0444 root root -"
  ];
}
