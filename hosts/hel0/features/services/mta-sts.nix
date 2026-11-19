{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  services = {
    traefik.dynamicConfigOptions.http = {
      routers.mta-sts = {
        entryPoints = ["https"]; # senders fetch the policy only over https
        rule = "Host(`mta-sts.${config.networking.domain}`)";

        service = "mta-sts";
      };

      services.mta-sts.loadBalancer.servers = [{url = "http://${config.services.static-web-server.listen}";}];
    };

    static-web-server = {
      enable = true;

      listen = "127.0.0.1:8787";

      root = pkgs.writeTextDir ".well-known/mta-sts.txt" (builtins.readFile ./mta-sts.txt);
      configuration.general.ignore-hidden-files = false; # the policy lives under `.well-known`
    };
  };
}
