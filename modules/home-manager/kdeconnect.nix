{lib, ...}: {
  options.services.kdeconnect.trustedDevices = with lib;
    mkOption {
      type = with types; attrsOf (attrsOf anything);

      default = {};
    };
}
