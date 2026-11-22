{
  # keep-sorted start
  config,
  lib,
  options,
  # keep-sorted end
  ...
}: {
  # lets another host's config read a service's port by name
  options.services._3proxy.namedServices = with lib;
    mkOption {
      type = with types; attrsOf options.services._3proxy.services.type.nestedTypes.elemType;

      default = {};
    };

  config.services._3proxy.services = lib.attrValues config.services._3proxy.namedServices;
}
