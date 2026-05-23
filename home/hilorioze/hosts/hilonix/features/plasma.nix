{
  programs.plasma.thermalMonitor = {
    Appearance.enableDangerColor = true;

    General.sensors = builtins.toJSON [
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

  xdg.configFile."kwinoutputconfig.json".text = builtins.toJSON [
    {
      name = "outputs";

      # edidIdentifier: python3 -c "import glob,struct;[print(f[16:-5].split('-',1)[1]+':',''.join(chr(((d[8]<<8|d[9])>>i&31)+64)for i in(10,5,0)),*struct.unpack('<HI',d[10:16]),d[16],d[17]+1990,0)for f in glob.glob('/sys/class/drm/card*-*/edid')if(d:=open(f,'rb').read())[16:]]"
      data = [
        {
          edidIdentifier = "RTK 15165 16843009 43 2020 0";

          transform = "Rotated90";
        }

        {
          edidIdentifier = "AOC 12802 1502 50 2023 0";
        }

        {
          edidIdentifier = "BNQ 32639 0 38 2020 0";

          mode = {
            width = 1920;
            height = 1080;

            refreshRate = 120000; # 144Hz fails on this monitor over MST Hub
          };
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

              priority = 3;

              position = {
                x = 0;
                y = 0;
              };
            }

            {
              enabled = true;

              outputIndex = 1;

              priority = 1;

              position = {
                x = 1080;
                y = 90;
              };
            }

            {
              enabled = true;

              outputIndex = 2;

              priority = 2;

              position = {
                x = 3640;
                y = 450;
              };
            }
          ];
        }

        {
          outputs = [
            {
              enabled = true;

              outputIndex = 0;

              priority = 2;

              position = {
                x = 0;
                y = 0;
              };
            }

            {
              enabled = true;

              outputIndex = 1;

              priority = 1;

              position = {
                x = 1080;
                y = 90;
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

              outputIndex = 2;

              priority = 2;

              position = {
                x = 2560;
                y = 360;
              };
            }
          ];
        }
      ];
    }
  ];
}
