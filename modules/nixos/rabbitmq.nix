{
  # keep-sorted start
  lib',
  lib,
  # keep-sorted end
  ...
}: let
  jsonAttrs = with lib.types; attrsOf json;
  tagsType = with lib.types; either str (listOf str);

  definitionsType = with lib;
  with types;
    submodule {
      options = {
        bindings = mkOption {
          type = lib'.options.listOfSubmodule {
            arguments = mkOption {
              type = jsonAttrs;

              default = {};
            };

            destination = mkOption {
              type = str;
            };

            destination_type = mkOption {
              type = enum [
                # keep-sorted start
                "exchange"
                "queue"
                # keep-sorted end
              ];
            };

            routing_key = mkOption {
              type = str;
            };

            source = mkOption {
              type = str;
            };

            vhost = mkOption {
              type = str;
            };
          };

          default = [];
        };

        exchanges = mkOption {
          type = lib'.options.listOfSubmodule {
            arguments = mkOption {
              type = jsonAttrs;

              default = {};
            };

            auto_delete = mkOption {
              type = bool;

              default = false;
            };

            durable = mkOption {
              type = bool;

              default = true;
            };

            internal = mkOption {
              type = bool;

              default = false;
            };

            name = mkOption {
              type = str;
            };

            type = mkOption {
              type = str;
            };

            vhost = mkOption {
              type = str;
            };
          };

          default = [];
        };

        global_parameters = mkOption {
          type = lib'.options.listOfSubmodule {
            name = mkOption {
              type = str;
            };

            value = mkOption {
              type = json;
            };
          };

          default = [];
        };

        parameters = mkOption {
          type = lib'.options.listOfSubmodule {
            component = mkOption {
              type = str;
            };

            name = mkOption {
              type = str;
            };

            value = mkOption {
              type = json;
            };

            vhost = mkOption {
              type = str;
            };
          };

          default = [];
        };

        permissions = mkOption {
          type = lib'.options.listOfSubmodule {
            configure = mkOption {
              type = str;
            };

            read = mkOption {
              type = str;
            };

            user = mkOption {
              type = str;
            };

            vhost = mkOption {
              type = str;
            };

            write = mkOption {
              type = str;
            };
          };

          default = [];
        };

        policies = mkOption {
          type = lib'.options.listOfSubmodule {
            apply-to = mkOption {
              type = enum [
                # keep-sorted start
                "all"
                "classic_queues"
                "exchanges"
                "queues"
                "quorum_queues"
                "streams"
                # keep-sorted end
              ];

              default = "all";
            };

            definition = mkOption {
              type = jsonAttrs;
            };

            name = mkOption {
              type = str;
            };

            pattern = mkOption {
              type = str;
            };

            priority = mkOption {
              type = int;

              default = 0;
            };

            vhost = mkOption {
              type = str;
            };
          };

          default = [];
        };

        queues = mkOption {
          type = lib'.options.listOfSubmodule {
            arguments = mkOption {
              type = jsonAttrs;

              default = {};
            };

            auto_delete = mkOption {
              type = bool;

              default = false;
            };

            durable = mkOption {
              type = bool;

              default = true;
            };

            exclusive = mkOption {
              type = bool;

              default = false;
            };

            name = mkOption {
              type = str;
            };

            type = mkOption {
              type = nullOr str;

              default = null;
            };

            vhost = mkOption {
              type = str;
            };
          };

          default = [];
        };

        rabbit_version = mkOption {
          type = nullOr str;

          default = null;
        };

        rabbitmq_version = mkOption {
          type = nullOr str;

          default = null;
        };

        topic_permissions = mkOption {
          type = lib'.options.listOfSubmodule {
            exchange = mkOption {
              type = str;
            };

            read = mkOption {
              type = str;
            };

            user = mkOption {
              type = str;
            };

            vhost = mkOption {
              type = str;
            };

            write = mkOption {
              type = str;
            };
          };

          default = [];
        };

        users = mkOption {
          type = lib'.options.listOfSubmodule {
            hashing_algorithm = mkOption {
              type = str;
            };

            limits = mkOption {
              type = json;

              default = {};
            };

            name = mkOption {
              type = str;
            };

            password_hash = mkOption {
              type = str;
            };

            tags = mkOption {
              type = tagsType;

              default = [];
            };
          };

          default = [];
        };

        vhosts = mkOption {
          type = lib'.options.listOfSubmodule {
            description = mkOption {
              type = nullOr str;

              default = null;
            };

            # `rabbitmq` exports vhost `limits` in definitions, but importing definitions does not restore them; the actual limit state lives in the `vhost-limits` runtime parameter
            # limits = mkOption {
            #   type = json;
            #
            #   default = {};
            # };

            metadata = mkOption {
              type = jsonAttrs;

              default = {};
            };

            name = mkOption {
              type = str;
            };

            tags = mkOption {
              type = listOf str;

              default = [];
            };

            tracing = mkOption {
              type = nullOr bool;

              default = null;
            };
          };

          default = [];
        };
      };
    };
in {
  options.services.rabbitmq.definitions = lib.mkOption {
    type = definitionsType;

    default = {};

    apply = lib'.attrsets.pruneAttrs;
  };
}
