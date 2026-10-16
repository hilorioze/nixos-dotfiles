_final: prev: {
  writeShellApplication = args:
    prev.writeShellApplication (
      args
      // {
        excludeShellChecks =
          (import ../../shared.nix).ignoredShellcheckRules
          ++ (args.excludeShellChecks or []);
      }
    );
}
