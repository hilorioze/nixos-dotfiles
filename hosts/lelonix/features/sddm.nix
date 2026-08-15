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
          --directory \
          --mode=0755 \
          --owner=sddm --group=sddm \
          ${sddmHome}/.config

        ${lib.getExe' pkgs.coreutils "install"} \
          --mode=0644 \
          --owner=sddm --group=sddm \
          ${kwinoutputConfig} \
          ${sddmHome}/.config/kwinoutputconfig.json
      '';
    };

    installSddmInputConfig = {
      deps = ["users"];

      text = ''
        ${lib.getExe' pkgs.coreutils "install"} \
          --directory \
          --mode=0755 \
          --owner=sddm --group=sddm \
          ${sddmHome}/.config

        ${lib.getExe' pkgs.coreutils "install"} \
          --mode=0644 \
          --owner=sddm --group=sddm \
          ${kcminputConfig} \
          ${sddmHome}/.config/kcminputrc
      '';
    };
  };
}
