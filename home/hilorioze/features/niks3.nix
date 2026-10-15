{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  # niks3's default xdg auth-token path instead of `NIKS3_AUTH_TOKEN_FILE`
  sops.secrets."credentials/niks3/servers/hilorioze/api-token".path = "${config.xdg.configHome}/niks3/auth-token";

  home = {
    sessionVariables.NIKS3_SERVER_URL = "https://niks3.hilorioze.com";

    packages = [pkgs.niks3];
  };
}
