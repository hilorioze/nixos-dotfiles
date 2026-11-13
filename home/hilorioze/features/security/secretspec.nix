{pkgs, ...}: {
  xdg.configFile."secretspec/config.toml".source = (pkgs.formats.toml {}).generate "secretspec-config.toml" {
    defaults.provider = "keyring"; # keep project secrets in keepassxc, which serves the secret service
  };
}
