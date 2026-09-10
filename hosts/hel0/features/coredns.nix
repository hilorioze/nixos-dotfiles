{
  imports = [../../common/features/coredns.nix];

  networking.resolvconf.useLocalResolver = false; # keep local DNS services from becoming the host's default resolver
}
