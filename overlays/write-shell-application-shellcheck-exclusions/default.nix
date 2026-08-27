_final: prev: let
  inherit (import ../../shared.nix) ignoredShellcheckRules;
in {
  writeShellApplication = args:
    prev.writeShellApplication (
      args
      // {
        excludeShellChecks =
          ignoredShellcheckRules
          ++ (args.excludeShellChecks or []);
      }
    );
}
