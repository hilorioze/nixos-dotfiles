{config, ...}: {
  sops = {
    secrets."apps/wakatime/api-key" = {};

    templates."apps/.wakatime.cfg" = {
      content = ''
        [settings]
        api_key = ${config.sops.placeholder."apps/wakatime/api-key"}
      '';

      path = "${config.home.homeDirectory}/.wakatime.cfg";
    };
  };
}
