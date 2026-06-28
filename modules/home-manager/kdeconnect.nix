{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  iniFormat = pkgs.formats.ini {};

  trustedDeviceType = with lib;
  with types;
    submodule (_: {
      options = {
        name = mkOption {
          type = str;
        };

        type = mkOption {
          type = str;
        };

        protocolVersion = mkOption {
          type = int;
        };

        certificate = mkOption {
          type = str;
        };
      };
    });

  trustedDevicesType = with lib.types; attrsOf trustedDeviceType;
in
  with lib; {
    options.services.kdeconnect.trustedDevices = mkOption {
      type = trustedDevicesType;

      default = {};
    };

    config = mkIf (config.services.kdeconnect.enable && config.services.kdeconnect.trustedDevices != {}) {
      xdg.configFile."kdeconnect/trusted_devices".source = iniFormat.generate "kdeconnect-trusted_devices.ini" config.services.kdeconnect.trustedDevices;
    };
  }
