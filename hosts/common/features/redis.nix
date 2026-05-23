{config, ...}: {
  sops = {
    secrets."services/redis/users/hilorioze/hashed-password" = {};

    templates."config/redis.acl" = {
      content = ''
        user default reset off

        user hilorioze reset on #${config.sops.placeholder."services/redis/users/hilorioze/hashed-password"} allkeys allchannels allcommands
      '';

      owner = config.services.redis.servers."".user;
    };
  };

  services.redis.servers."" = {
    enable = true;

    bind = "0.0.0.0";

    settings.aclfile = config.sops.templates."config/redis.acl".path;
  };
}
