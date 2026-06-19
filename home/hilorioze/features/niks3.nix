{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets."credentials/niks3/servers/hilorioze/api-token" = {};

  home = {
    sessionVariables = {
      NIKS3_SERVER_URL = "https://niks3.hilorioze.com";

      NIKS3_AUTH_TOKEN_FILE = config.sops.secrets."credentials/niks3/servers/hilorioze/api-token".path;
    };

    packages = [pkgs.niks3];
  };
}
