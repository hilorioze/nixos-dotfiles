{
  # keep-sorted start
  config,
  outputs,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets = {
    # keep-sorted start
    "credentials/attic/servers/hilorioze/token" = {};
    "credentials/attic/servers/rayttage/token" = {};
    # keep-sorted end
  };

  xdg.configFile."attic/config.toml".source = (pkgs.formats.toml {}).generate "attic-config.toml" {
    default-server = "hilorioze";

    servers = {
      # keep-sorted start block=yes newline_separated=yes
      hilorioze = {
        endpoint = outputs.nixosConfigurations.de0.config.services.atticd.settings.api-endpoint;

        token-file = config.sops.secrets."credentials/attic/servers/hilorioze/token".path;
      };

      rayttage = {
        endpoint = "https://attic.rayttage.net/";

        token-file = config.sops.secrets."credentials/attic/servers/rayttage/token".path;
      };
      # keep-sorted end
    };
  };
}
