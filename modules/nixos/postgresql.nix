{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  options.services.postgresql.authRules = with lib;
    mkOption {
      type = with lib.types; listOf str;

      default = [];
    };

  config = lib.mkIf config.services.postgresql.enable {
    services.postgresql.authentication = lib.mkForce (lib.concatStringsSep "\n" config.services.postgresql.authRules);
  };
}
