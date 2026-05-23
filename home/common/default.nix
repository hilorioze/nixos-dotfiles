{
  # keep-sorted start
  lib,
  osConfig,
  outputs,
  # keep-sorted end
  ...
}: {
  imports = [./features] ++ (builtins.attrValues outputs.homeModules);

  home.stateVersion = lib.mkDefault osConfig.system.stateVersion;
}
