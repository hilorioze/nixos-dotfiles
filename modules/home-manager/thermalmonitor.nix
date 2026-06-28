{
  # keep-sorted start
  lib',
  lib,
  # keep-sorted end
  ...
}: let
  sensorType = with lib;
  with types;
    submodule {
      options = {
        name = mkOption {
          type = str;
        };

        sensorId = mkOption {
          type = str;
        };
      };
    };

  temperatureUnitChoices = [
    # keep-sorted start
    "celsius"
    "fahrenheit"
    # keep-sorted end
  ];

  temperatureUnitType = with lib.types; enum temperatureUnitChoices;

  toUpstreamConfig = config:
    lib'.attrsets.pruneAttrs {
      Appearance = config.appearance;
      Behavior = config.behavior;
      General = config.general;
      State = config.state;
    };

  thermalMonitorType = with lib;
  with types;
    submodule {
      options = {
        appearance = mkOption {
          type = submodule {
            options = {
              chartAutomaticScale = lib'.options.nullable bool;
              chartFromY = lib'.options.nullable int;
              chartToY = lib'.options.nullable int;
              enableDangerColor = lib'.options.nullable bool;
              fontScale = lib'.options.nullable number;
              meltdownThreshold = lib'.options.nullable int;
              showStats = lib'.options.nullable bool;
              showUnit = lib'.options.nullable bool;
              swapLabels = lib'.options.nullable bool;
              warningThreshold = lib'.options.nullable int;
            };
          };

          default = {};
        };

        behavior = mkOption {
          type = submodule {
            options = {
              scrollApplet = lib'.options.nullable bool;
              scrollAppletOpensPopup = lib'.options.nullable bool;
              scrollPopup = lib'.options.nullable bool;
              scrollWraparound = lib'.options.nullable bool;
              statsHistory = lib'.options.nullable int;
              temperatureUnit = lib'.options.nullable temperatureUnitType;
              updateInterval = lib'.options.nullable number;
            };
          };

          default = {};
        };

        general = mkOption {
          type = submodule {
            options.sensors =
              (lib'.options.nullable (listOf sensorType))
              // {
                apply = sensors:
                  if sensors == null
                  then null
                  else builtins.toJSON sensors;
              };
          };

          default = {};
        };

        state = mkOption {
          type = submodule {
            options.pinned = lib'.options.nullable bool;
          };

          default = {};
        };
      };
    };
in
  with lib; {
    options.programs.thermalmonitor.settings = mkOption {
      type = thermalMonitorType;

      default = {};

      apply = toUpstreamConfig;
    };
  }
