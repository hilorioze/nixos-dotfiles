{lib, ...}: {
  options.virtualisation.agentbox =
    with lib;
    with types; {
      domain = mkOption {
        type = str;
      };

      bridge = {
        address = mkOption {
          type = str;
        };

        prefixLength = mkOption {
          type = ints.between 0 32;
        };
      };

      mcpProxy.port = mkOption {
        type = port;
      };

      machines = mkOption {
        type = attrsOf (submodule {
          options = {
            address = mkOption {
              type = str;
            };

            preauthKeyPrefix = mkOption {
              type = str;
            };

            sshHostKey = mkOption {
              type = str;
            };
          };
        });

        default = {};
      };
    };
}
