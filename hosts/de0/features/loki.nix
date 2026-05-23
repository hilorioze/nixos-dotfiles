{config, ...}: {
  services.loki = {
    enable = true;

    configuration = {
      auth_enabled = false;

      common = {
        path_prefix = config.services.loki.dataDir;

        replication_factor = 1;

        ring = {
          # bypass interface auto-detection; avoids occasional "no useable address found" errors
          # (required by internal clustering logic, but completely irrelevant in our case)
          instance_addr = "127.0.0.1";

          kvstore.store = "inmemory";
        };
      };

      schema_config.configs = [
        {
          from = "2026-04-01";

          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";

          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
    };
  };
}
