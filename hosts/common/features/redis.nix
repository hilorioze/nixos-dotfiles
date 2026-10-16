{config, ...}: {
  sops = {
    secrets."services/redis/users/hilorioze/hashed-password" = {};

    templates."services/redis.acl" = {
      content = ''
        user default reset off

        user hilorioze reset on #${config.sops.placeholder."services/redis/users/hilorioze/hashed-password"} allkeys allchannels allcommands
      '';

      owner = config.services.redis.servers."".user;

      restartUnits = ["redis.service"];
    };
  };

  services.redis.servers."" = {
    enable = true;

    bind = "0.0.0.0";

    settings.aclfile = config.sops.templates."services/redis.acl".path;
  };
}
