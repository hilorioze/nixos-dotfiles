{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: let
  botSettings = {
    # keep-sorted start
    dgarmo_ens = {};
    hiloriozesteamserver1 = {};
    # keep-sorted end
  };

  commonBotSettings = {
    OnlineStatus = 0; # `Offline`

    FarmingPreferences = 16; # `SkipRefundableGames`

    RemoteCommunication = 0; # no third-party communication allowed
  };
in {
  sops.secrets = let
    archisteamfarmSecret = {
      group = config.systemd.services.archisteamfarm.serviceConfig.Group;
      mode = "0440";

      restartUnits = ["archisteamfarm.service"];
    };
  in
    lib.mkMerge [
      {"services/archisteamfarm/ipc-password" = archisteamfarmSecret;}

      (lib.mapAttrs' (name: _: lib.nameValuePair "services/archisteamfarm/bots/${name}/password" archisteamfarmSecret) botSettings)
    ];

  services = {
    traefik.dynamicConfigOptions.http = {
      routers = {
        archisteamfarm-http = {
          entryPoints = ["http"];
          rule = "Host(`archisteamfarm.${config.networking.fqdn}`)";

          middlewares = ["redirect-to-https"];

          service = "noop@internal";
        };

        archisteamfarm = {
          entryPoints = ["https"];
          rule = "Host(`archisteamfarm.${config.networking.fqdn}`)";

          service = "archisteamfarm";
        };
      };

      services.archisteamfarm.loadBalancer.servers = [{url = "http://127.0.0.1:1242";}];
    };

    archisteamfarm = {
      enable = true;

      web-ui.enable = true;

      ipcPasswordFile = config.sops.secrets."services/archisteamfarm/ipc-password".path;

      bots =
        lib.mapAttrs (name: specificBotSettings: {
          passwordFile = config.sops.secrets."services/archisteamfarm/bots/${name}/password".path;

          settings = lib.recursiveUpdate commonBotSettings specificBotSettings;
        })
        botSettings;

      settings.SteamTokenDumperPluginEnabled = true;
    };
  };
}
