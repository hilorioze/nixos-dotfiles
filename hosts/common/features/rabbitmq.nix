{config, ...}: {
  sops = {
    secrets."services/rabbitmq/users/hilorioze/hashed-password" = {};

    templates."config/rabbitmq-definitions.json" = {
      content = builtins.toJSON config.services.rabbitmq.definitions;

      owner = config.systemd.services.rabbitmq.serviceConfig.User;
    };
  };

  services.rabbitmq = {
    enable = true;

    listenAddress = "0.0.0.0";

    configItems.load_definitions = config.sops.templates."config/rabbitmq-definitions.json".path;

    definitions = {
      users = [
        {
          name = "hilorioze";

          password_hash = config.sops.placeholder."services/rabbitmq/users/hilorioze/hashed-password";
          hashing_algorithm = "rabbit_password_hashing_sha256";

          tags = ["administrator"];
        }
      ];

      vhosts = [
        {
          name = "/";
        }
      ];

      permissions = [
        {
          user = "hilorioze";

          vhost = "/";

          configure = ".*";
          write = ".*";
          read = ".*";
        }
      ];
    };
  };
}
