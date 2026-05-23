{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: let
  commonBotSettings = {
    OnlineStatus = 0; # Offline

    FarmingPreferences = 16; # SkipRefundableGames (16)

    RemoteCommunication = 0; # No allowed third-party communication
  };

  botSettings = {
    # keep-sorted start
    dgarmo_ens = {};
    hiloriozesteamserver1 = {};
    # keep-sorted end
  };

  botSecretsList = map (name: {
    "services/archisteamfarm/bots/${name}/password" = {
      group = config.systemd.services.archisteamfarm.serviceConfig.Group;

      mode = "0440"; # give read access for the group we just set above
    };
  }) (builtins.attrNames botSettings);
in {
  sops.secrets = lib.attrsets.mergeAttrsList (
    [
      {
        "services/archisteamfarm/ipc-password" = {
          group = config.systemd.services.archisteamfarm.serviceConfig.Group;

          mode = "0440"; # give read access for the group we just set above
        };
      }
    ]
    ++ botSecretsList
  );

  services.traefik.dynamicConfigOptions.http = {
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

  services.archisteamfarm = {
    enable = true;

    web-ui.enable = true;

    ipcPasswordFile = config.sops.secrets."services/archisteamfarm/ipc-password".path;

    bots =
      lib.attrsets.mapAttrs
      (
        name: specificBotSettings: {
          passwordFile = config.sops.secrets."services/archisteamfarm/bots/${name}/password".path;
          settings = lib.attrsets.recursiveUpdate commonBotSettings specificBotSettings;
        }
      )
      botSettings;

    settings.SteamTokenDumperPluginEnabled = true;
  };
}
