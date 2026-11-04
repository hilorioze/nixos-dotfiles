{
  programs.thermalmonitor.settings = {
    appearance.enableDangerColor = true;

    general.sensors = [
      {
        name = "CPU";

        sensorId = "cpu/all/averageTemperature";
      }
      {
        name = "DIMM";

        sensorId = "lmsensors/spd5118-i2c-0-50/temp1";
      }
      {
        name = "GPU";

        sensorId = "gpu/gpu1/temperature";
      }
      {
        name = "NVMe-0A";

        sensorId = "lmsensors/nvme-pci-0300/temp1";
      }
      {
        name = "WiFi";

        sensorId = "lmsensors/iwlwifi_1-virtual-0/temp1";
      }
    ];
  };
}
