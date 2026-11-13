{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops = {
    # , openssl rand -hex 32
    secrets."services/garage/rpc-secret" = {};

    templates."services/garage.env" = {
      content = "GARAGE_RPC_SECRET=${config.sops.placeholder."services/garage/rpc-secret"}";

      restartUnits = ["garage.service"];
    };
  };

  services.garage = {
    enable = true;

    package = pkgs.garage_2;

    environmentFile = config.sops.templates."services/garage.env".path;

    settings = {
      db_engine = "sqlite"; # lmdb can get corrupted by an unclean shutdown, and a single node has no replica to rebuild it from
      replication_factor = 1;

      rpc_bind_addr = "127.0.0.1:3901"; # the cli connects here as well while `rpc_public_addr` is unset

      s3_api = {
        api_bind_addr = "127.0.0.1:3900";

        s3_region = "garage";
      };
    };
  };

  systemd.services = {
    garage.serviceConfig.ExecStart = lib.mkForce "${lib.getExe config.services.garage.package} server --single-node"; # give the node the whole layout on the first start

    # clients append their buckets and keys to the script
    garage-setup = {
      wantedBy = ["multi-user.target"];

      requires = ["garage.service"];
      after = ["garage.service"];

      path = [config.services.garage.package];

      serviceConfig = {
        Type = "oneshot";

        RemainAfterExit = "yes";

        EnvironmentFile = config.services.garage.environmentFile;
      };

      script = ''
        until garage status >/dev/null 2>&1; do
          sleep 1
        done
      '';
    };
  };
}
