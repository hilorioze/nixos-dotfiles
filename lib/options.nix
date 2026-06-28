{lib}: {
  listOfSubmodule = options:
    with lib.types;
      listOf (submodule {inherit options;});

  nullable = type:
    with lib;
      mkOption {
        type = with types; nullOr type;

        default = null;
      };
}
