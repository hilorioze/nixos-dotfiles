{
  programs.plasma.thermalMonitor = {
    Appearance.enableDangerColor = true;

    General.sensors = builtins.toJSON [
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

  xdg.configFile."kwinoutputconfig.json".text = builtins.toJSON [
    {
      name = "outputs";

      # edidIdentifier: python3 -c "import glob,struct;[print(f[16:-5].split('-',1)[1]+':',''.join(chr(((d[8]<<8|d[9])>>i&31)+64)for i in(10,5,0)),*struct.unpack('<HI',d[10:16]),d[16],d[17]+1990,0)for f in glob.glob('/sys/class/drm/card*-*/edid')if(d:=open(f,'rb').read())[16:]]"
      data = [
        {
          edidIdentifier = "BOE 2591 0 18 2021 0";

          scale = 1.5;

          vrrPolicy = "Automatic";
        }
        {
          uuid = "454c8308-647d-4ac2-af1a-f02ab47e614b";

          edidIdentifier = "MSI 40130 0 5 2024 0";

          vrrPolicy = "Automatic";
        }
      ];
    }

    {
      name = "setups";

      data = [
        {
          outputs = [
            {
              enabled = true;

              outputIndex = 0;

              position = {
                x = 0;
                y = 0;
              };
            }
          ];
        }

        {
          outputs = [
            {
              enabled = true;

              outputIndex = 1;

              priority = 1;

              position = {
                x = 0;
                y = 0;
              };
            }

            {
              enabled = true;

              outputIndex = 0;

              priority = 2;

              position = {
                x = 2560;
                y = 0;
              };

              replicationSource = "454c8308-647d-4ac2-af1a-f02ab47e614b";
            }
          ];
        }
      ];
    }
  ];
}
