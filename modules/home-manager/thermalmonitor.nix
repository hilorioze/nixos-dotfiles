{lib, ...}: {
  options.programs.plasma.thermalMonitor = with lib;
    mkOption {
      type = with types; attrsOf (attrsOf anything);

      default = {};
    };
}
