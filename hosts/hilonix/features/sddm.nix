{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  sddmHome = config.users.users.sddm.home;

  kwinoutputConfig = pkgs.writeText "sddm-kwinoutputconfig.json" (builtins.toJSON [
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
  ]);

  kcminputConfig = pkgs.writeText "sddm-kcminputrc" ''
    [Keyboard]
    RepeatDelay=200
    RepeatRate=50.0

    [Libinput][11944][8707][Wings Tech Xtrfy M4]
    Enabled=true
    PointerAccelerationProfile=1

    [Libinput][9639][64146][Xtrfy Xtrfy Wireless Mouse]
    Enabled=true
    PointerAccelerationProfile=1

    [Libinput][9639][64153][Xtrfy Xtrfy Wireless Receiver]
    Enabled=true
    PointerAccelerationProfile=1
  '';
in {
  imports = [../../common/features/sddm.nix];

  system.activationScripts = {
    installSddmKwinOutputConfig = {
      deps = ["users"];

      text = ''
        ${lib.getExe' pkgs.coreutils "install"} \
          -d \
          -m 0755 \
          -o sddm -g sddm \
          "${sddmHome}/.config"

        ${lib.getExe' pkgs.coreutils "install"} \
          -m 0644 \
          -o sddm -g sddm \
          "${kwinoutputConfig}" \
          "${sddmHome}/.config/kwinoutputconfig.json"
      '';
    };

    installSddmInputConfig = {
      deps = ["users"];

      text = ''
        ${lib.getExe' pkgs.coreutils "install"} \
          -d \
          -m 0755 \
          -o sddm -g sddm \
          "${sddmHome}/.config"

        ${lib.getExe' pkgs.coreutils "install"} \
          -m 0644 \
          -o sddm -g sddm \
          "${kcminputConfig}" \
          "${sddmHome}/.config/kcminputrc"
      '';
    };
  };
}
