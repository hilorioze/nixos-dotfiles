{config, ...}: {
  sops = {
    secrets = {
      # keep-sorted start block=yes newline_separated=yes
      "credentials/ghcr/hilorioze/pull/token" = {};

      "services/mspanel/mysql/database" = {};

      "services/mspanel/mysql/host" = {};

      "services/mspanel/mysql/password" = {};

      "services/mspanel/mysql/user" = {};

      "services/mspanel/users" = {
        inherit (config.users.users.${config.systemd.services.traefik.serviceConfig.User}) group; # bind the secret to the traefik user's group, so changing `services.traefik.group` won't leak it; upstream sets the user's group to "traefik": https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/nixos/modules/services/web-servers/traefik.nix#L160

        mode = "0440"; # give read access for the group we just set above
      };
      # keep-sorted end
    };

    templates."services/mspanel/mysql.env".content = ''
      # keep-sorted start
      MYSQL_DATABASE=${config.sops.placeholder."services/mspanel/mysql/database"}
      MYSQL_HOST=${config.sops.placeholder."services/mspanel/mysql/host"}
      MYSQL_PASSWORD=${config.sops.placeholder."services/mspanel/mysql/password"}
      MYSQL_USER=${config.sops.placeholder."services/mspanel/mysql/user"}
      # keep-sorted end
    '';
  };

  virtualisation.oci-containers.containers.mspanel = {
    image = "ghcr.io/bloodzoneru/mspanel@sha256:ea13379f03ef25be2176ceb0bf7f9ba28041cbcdf45e72ce6c51c98fe067f4d0"; # 892cf2d

    login = {
      registry = "ghcr.io";

      username = "hilorioze";
      passwordFile = config.sops.secrets."credentials/ghcr/hilorioze/pull/token".path;
    };

    environmentFiles = [config.sops.templates."services/mspanel/mysql.env".path];

    labels = {
      "traefik.enable" = "true";

      "traefik.http.routers.mspanel-http.entryPoints" = "http";
      "traefik.http.routers.mspanel-http.rule" = "Host(`mspanel.${config.networking.fqdn}`)";
      "traefik.http.routers.mspanel-http.middlewares" = "redirect-to-https@file";
      "traefik.http.routers.mspanel-http.service" = "noop@internal";

      "traefik.http.routers.mspanel.entryPoints" = "https";
      "traefik.http.routers.mspanel.rule" = "Host(`mspanel.${config.networking.fqdn}`)";
      "traefik.http.routers.mspanel.middlewares" = "mspanel-auth";
      "traefik.http.middlewares.mspanel-auth.basicAuth.usersFile" = config.sops.secrets."services/mspanel/users".path;
      "traefik.http.routers.mspanel.service" = "mspanel";

      "traefik.http.services.mspanel.loadBalancer.server.port" = "3000";
    };
  };
}
