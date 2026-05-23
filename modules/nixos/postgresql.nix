{lib, ...}: {
  options.services.postgresql.authRules = with lib;
    mkOption {
      type = with types; listOf str;

      default = [];
    };
}
