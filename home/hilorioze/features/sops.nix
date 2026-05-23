{lib, ...}: {
  sops.defaultSopsFile = lib.mkDefault ../secrets.yaml;
}
