{
  networking.networkmanager = {
    enable = true;

    wifi.powersave = false; # prevent latency spikes
  };
}
