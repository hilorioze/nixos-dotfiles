{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets."credentials/attic/servers/rayttage/token" = {};

  xdg.configFile."attic/config.toml".source = (pkgs.formats.toml {}).generate "attic-config.toml" {
    servers.rayttage = {
      endpoint = "https://attic.rayttage.net/";

      token-file = config.sops.secrets."credentials/attic/servers/rayttage/token".path;
    };
  };
}
