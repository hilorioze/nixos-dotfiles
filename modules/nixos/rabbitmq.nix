{lib, ...}: {
  options.services.rabbitmq.definitions = with lib;
    mkOption {
      type = with types; attrsOf (listOf anything);

      default = {};
    };
}
