{
  imports = [../../../common/features/services/coredns.nix];

  networking.resolvconf.useLocalResolver = false; # keep local dns services from becoming the host's default resolver
}
