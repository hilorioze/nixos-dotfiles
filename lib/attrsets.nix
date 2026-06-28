{lib}: let
  pruneAttrs = value:
    if builtins.isAttrs value
    then
      lib.filterAttrsRecursive (_: childValue: childValue != null && childValue != {}) (
        lib.mapAttrs (_: pruneAttrs) value
      )
    else if builtins.isList value
    then map pruneAttrs value
    else value;
in {
  inherit pruneAttrs;
}
