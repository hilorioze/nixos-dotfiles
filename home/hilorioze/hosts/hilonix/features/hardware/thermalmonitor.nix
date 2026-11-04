{
  programs.thermalmonitor.settings = {
    appearance.enableDangerColor = true;

    general.sensors = [
      {
        name = "CPU";

        sensorId = "cpu/all/averageTemperature";
      }
      {
        name = "DIMM-A2";

        sensorId = "lmsensors/spd5118-i2c-1-51/temp1";
      }
      {
        name = "DIMM-B2";

        sensorId = "lmsensors/spd5118-i2c-1-53/temp1";
      }
      {
        name = "iGPU";

        sensorId = "gpu/gpu2/temperature";
      }
      {
        name = "dGPU";

        sensorId = "gpu/gpu1/temperature";
      }
      {
        name = "NVMe-0B";

        sensorId = "lmsensors/nvme-pci-0b00/temp1";
      }
      {
        name = "WiFi";

        sensorId = "lmsensors/mt7921_phy0-pci-0800/temp1";
      }
    ];
  };
}
