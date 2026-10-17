{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  inherit (config.networking) domain;

  authentikHost = "idm.${domain}";
  authentikHttpAddress = lib.head config.services.authentik.settings.listen.http;
  authentikLdapAddress = lib.head config.services.authentik.settings.listen.ldap;
  ldapHost = config.networking.fqdn;

  users = ["hilorioze"]; # each also needs its block in `authentik/users.yaml`
  mkInitialPasswordSecret = username: "services/authentik/users/${username}/initial-password";

  # bootstrap-only throwaway hash
  bootstrapPasswordHash = "pbkdf2_sha256$1000000$VtonnTnTF8QFxmNWSgCcf2$gUd6YTti7U4tXhh9LUJ5QWCKroJe3anKm5B47dhqWLk=";

  # reapply `!File` values when the secret's sops source changes
  mailBlueprint = pkgs.writeText "mail.yaml" ''
    ${builtins.readFile ./authentik/mail.yaml}

    # sops-trigger: ${config.sops.secrets."services/authentik/ldap/users/mail-directory/password".sopsFileHash}
  '';

  # reapply `!File` values when the secret's sops source changes
  ldapOutpostBlueprint = pkgs.writeText "ldap-outpost.yaml" ''
    ${builtins.readFile ./authentik/ldap-outpost.yaml}

    # sops-trigger: ${config.sops.secrets."services/authentik/ldap/outposts/mail-directory/token".sopsFileHash}
  '';

  blueprints = pkgs.runCommand "authentik-blueprints" {} ''
    mkdir --parents $out

    cp --recursive \
      ${config.services.authentik.authentikComponents.staticWorkdirDeps}/blueprints/. \
      $out/

    install --mode 0644 ${mailBlueprint} $out/mail.yaml
    install --mode 0644 ${./authentik/ldap.yaml} $out/ldap.yaml
    install --mode 0644 ${ldapOutpostBlueprint} $out/ldap-outpost.yaml
    install --mode 0644 ${pkgs.replaceVars ./authentik/traefik.yaml {inherit domain;}} $out/traefik.yaml
    install --mode 0644 ${pkgs.replaceVars ./authentik/users.yaml {inherit domain;}} $out/users.yaml
  '';
in {
  imports = [inputs.authentik-nix.nixosModules.default];

  sops = {
    secrets =
      {
        # keep-sorted start block=yes newline_separated=yes
        "services/authentik/ldap/outposts/mail-directory/token".restartUnits = ["authentik-ldap.service"];

        "services/authentik/ldap/users/mail-directory/password" = {};

        "services/authentik/secret-key".restartUnits = ["authentik-worker.service"]; # authentik requires the worker and restarts with it
        # keep-sorted end
      }
      // lib.genAttrs (map mkInitialPasswordSecret users) (_: {});

    templates = {
      "services/authentik/secret-key.env".content = "AUTHENTIK_SECRET_KEY=${config.sops.placeholder."services/authentik/secret-key"}";

      "services/authentik-ldap/outpost.env".content = ''
        AUTHENTIK_HOST=http://${authentikHttpAddress}

        AUTHENTIK_TOKEN=${config.sops.placeholder."services/authentik/ldap/outposts/mail-directory/token"}
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    # keep-sorted start numeric=yes
    6636
    9443
    # keep-sorted end
  ];

  services = {
    postgresql.authRules = ["local authentik authentik peer"];

    authentik = {
      enable = true;

      environmentFile = config.sops.templates."services/authentik/secret-key.env".path;

      settings = {
        blueprints_dir = blueprints;

        listen = {
          http = ["127.0.0.1:9000"];
          https = []; # disable default `[::]:9443`; traefik terminates tls

          ldap = ["127.0.0.1:3389"];
          ldaps = []; # traefik terminates tls

          metrics = []; # disable unused default `[::]:9300`
          radius = []; # disable unused default `[::]:1812`
        };
      };

      worker.listenHTTP = "127.0.0.1:9001"; # use ipv4 loopback instead of default `[::1]:9001`
    };

    authentik-ldap = {
      enable = true;

      listenMetrics = ""; # disable unused default `[::1]:9302`

      environmentFile = config.sops.templates."services/authentik-ldap/outpost.env".path;
    };

    traefik = {
      dynamicConfigOptions = {
        http = {
          middlewares.oidc-login.forwardAuth.address = "http://${authentikHttpAddress}/outpost.goauthentik.io/auth/traefik"; # the embedded outpost through loopback instead of the `forward-auth` entrypoint

          routers = {
            authentik-http = {
              entryPoints = ["http"];
              rule = "Host(`${authentikHost}`)";

              middlewares = ["redirect-to-https"];

              service = "noop@internal";
            };

            authentik = {
              entryPoints = ["https"];
              rule = "Host(`${authentikHost}`)";

              service = "authentik";
            };

            authentik-forward-auth = {
              entryPoints = ["forward-auth"];
              rule = "Host(`${authentikHost}`) && Path(`/outpost.goauthentik.io/auth/traefik`)";

              service = "authentik";
            };
          };

          services.authentik.loadBalancer.servers = [{url = "http://${authentikHttpAddress}";}];
        };

        tcp = {
          routers.authentik-ldap = {
            entryPoints = ["ldaps"];
            rule = "HostSNI(`${ldapHost}`)";

            tls.certResolver = "cloudflare";
            service = "authentik-ldap";
          };

          services.authentik-ldap.loadBalancer = {
            servers = [{address = authentikLdapAddress;}];

            serversTransport = "authentik-ldap";
          };

          serversTransports.authentik-ldap.proxyProtocol = {}; # pass client addresses on, so authentik's brute-force protection sees them instead of traefik's loopback
        };
      };

      staticConfigOptions.entryPoints = {
        # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=address\s*=\s*[^;]*?:(\d+)
        ldaps.address = ":6636";

        # the other hosts' traefik asks the embedded outpost here whether a request may pass
        forward-auth = {
          address = ":9443";

          http.tls.certResolver = "cloudflare";

          forwardedHeaders.insecure = true; # the outpost picks the app by their `X-Forwarded-*` headers; spoofing them here gains nothing, since this entrypoint serves only the session check, not the login or any service
        };
        # keep-sorted end
      };
    };
  };

  systemd.services = {
    authentik-ldap.restartTriggers = [config.environment.etc."authentik/config.yml".source]; # the module restarts only the server and worker on a config change, leaving the outpost on its old listeners

    authentik-worker = {
      environment = {
        AUTHENTIK_BOOTSTRAP_PASSWORD_HASH = bootstrapPasswordHash;

        AUTHENTIK_LISTEN__METRICS = lib.mkForce null; # inherit `listen.metrics`; the worker rejects an empty environment override
      };

      serviceConfig.LoadCredential = let
        mkInitialPasswordLoadCredential = username: "initial-password-${username}:${config.sops.secrets.${mkInitialPasswordSecret username}.path}";
      in
        map mkInitialPasswordLoadCredential users
        ++ [
          # keep-sorted start
          "ldap-bind-password:${config.sops.secrets."services/authentik/ldap/users/mail-directory/password".path}"
          "ldap-outpost-token:${config.sops.secrets."services/authentik/ldap/outposts/mail-directory/token".path}"
          # keep-sorted end
        ];
    };
  };
}
