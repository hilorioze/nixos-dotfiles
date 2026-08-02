{
  xdg.configFile."kwinoutputconfig.json".text = builtins.toJSON [
    {
      name = "outputs";

      # edidIdentifier: python3 -c "import glob,struct;[print(f[16:-5].split('-',1)[1]+':',''.join(chr(((d[8]<<8|d[9])>>i&31)+64)for i in(10,5,0)),*struct.unpack('<HI',d[10:16]),d[16],d[17]+1990,0)for f in glob.glob('/sys/class/drm/card*-*/edid')if(d:=open(f,'rb').read())[16:]]"
      data = [
        {
          edidIdentifier = "AOC 12802 1502 50 2023 0";
        }

        {
          edidIdentifier = "BNQ 32640 16843009 38 2020 0";
        }

        {
          edidIdentifier = "MSI 40130 0 5 2024 0";

          mode = {
            width = 2560;
            height = 1440;

            refreshRate = 144001; # higher refresh rates fail with the current MST hub and DP cable
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

              outputIndex = 1;

              priority = 2;

              position = {
                x = 0;
                y = 360;
              };
            }

            {
              enabled = true;

              outputIndex = 0;

              priority = 1;

              position = {
                x = 1920;
                y = 0;
              };
            }

            {
              enabled = true;

              outputIndex = 2;

              priority = 3;

              position = {
                x = 4480;
                y = 0;
              };
            }
          ];
        }
      ];
    }
  ];
}
