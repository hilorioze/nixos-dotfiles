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
  ldapHost = config.networking.fqdn;

  mkInitialPasswordCredential = username: "initial-password-${username}";
  mkInitialPasswordSecret = username: "services/authentik/users/${username}/initial-password";

  getUserPasswordSecret = username: builtins.getAttr (mkInitialPasswordSecret username) config.sops.secrets;

  # bootstrap-only throwaway hash
  bootstrapPasswordHash = "pbkdf2_sha256$1000000$VtonnTnTF8QFxmNWSgCcf2$gUd6YTti7U4tXhh9LUJ5QWCKroJe3anKm5B47dhqWLk=";

  users.hilorioze.groups = [
    # keep-sorted start
    "authentik Admins"
    "mail-users"
    # keep-sorted end
  ];

  usersBlueprint = pkgs.writeText "users.yaml" (import ./authentik/users.nix {
    inherit domain lib mkInitialPasswordCredential users;
  });

  # reapply `!File` values when the secret's SOPS source changes
  mailBlueprint = pkgs.writeText "mail.yaml" ''
    ${builtins.readFile ./authentik/mail.yaml}

    # sops-trigger: ${config.sops.secrets."services/authentik/ldap/users/mail-directory/password".sopsFileHash}
  '';

  # reapply `!File` values when the secret's SOPS source changes
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
    install --mode 0644 ${pkgs.replaceVars ./authentik/ldap.yaml {inherit ldapHost;}} $out/ldap.yaml
    install --mode 0644 ${ldapOutpostBlueprint} $out/ldap-outpost.yaml
    install --mode 0644 ${usersBlueprint} $out/users.yaml
  '';
in {
  imports = [inputs.authentik-nix.nixosModules.default];

  sops = {
    secrets =
      {
        # keep-sorted start block=yes newline_separated=yes
        "services/authentik/ldap/outposts/mail-directory/token".restartUnits = ["authentik-ldap.service"];

        "services/authentik/ldap/users/mail-directory/password" = {};

        "services/authentik/secret-key".restartUnits = [
          # keep-sorted start
          "authentik-worker.service"
          "authentik.service"
          # keep-sorted end
        ];
        # keep-sorted end
      }
      // lib.mapAttrs' (username: _: lib.nameValuePair (mkInitialPasswordSecret username) {}) users;

    templates = {
      "services/authentik/secret-key.env".content = "AUTHENTIK_SECRET_KEY=${config.sops.placeholder."services/authentik/secret-key"}";

      "services/authentik-ldap/outpost.env".content = ''
        AUTHENTIK_HOST=http://${authentikHttpAddress}

        AUTHENTIK_TOKEN=${config.sops.placeholder."services/authentik/ldap/outposts/mail-directory/token"}
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [6636];

  services = {
    postgresql.authRules = ["local authentik authentik peer"];

    authentik = {
      enable = true;

      environmentFile = config.sops.templates."services/authentik/secret-key.env".path;

      settings = {
        blueprints_dir = blueprints;

        listen = {
          http = ["127.0.0.1:9000"];
          https = []; # disable default `[::]:9443`; `traefik` terminates TLS

          ldap = [];
          ldaps = ["0.0.0.0:6636"];

          metrics = []; # disable unused default `[::]:9300`
          radius = []; # disable unused default `[::]:1812`
        };
      };

      worker.listenHTTP = "127.0.0.1:9001"; # use IPv4 loopback instead of default `[::1]:9001`
    };

    authentik-ldap = {
      enable = true;

      listenMetrics = ""; # disable unused default `[::1]:9302`

      environmentFile = config.sops.templates."services/authentik-ldap/outpost.env".path;
    };

    traefik.dynamicConfigOptions.http = {
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
      };

      services.authentik.loadBalancer.servers = [{url = "http://${authentikHttpAddress}";}];
    };
  };

  security.acme.certs.${ldapHost} = {
    dnsProvider = "cloudflare";

    credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."credentials/cloudflare/zones/${domain}/dns01-token".path;

    reloadServices = ["authentik-worker.service"];
  };

  systemd.services.authentik-worker = {
    after = ["acme-${ldapHost}.service"];

    environment = {
      AUTHENTIK_BOOTSTRAP_PASSWORD_HASH = bootstrapPasswordHash;

      AUTHENTIK_LISTEN__METRICS = lib.mkForce null; # inherit `listen.metrics`; the worker rejects an empty environment override
    };

    requires = ["acme-${ldapHost}.service"];

    serviceConfig.LoadCredential = let
      mkInitialPasswordLoadCredential = username: "${mkInitialPasswordCredential username}:${(getUserPasswordSecret username).path}";
    in
      lib.mapAttrsToList (username: _: mkInitialPasswordLoadCredential username) users
      ++ [
        # keep-sorted start
        "ldap-bind-password:${config.sops.secrets."services/authentik/ldap/users/mail-directory/password".path}"
        "ldap-certificate-key:${config.security.acme.certs.${ldapHost}.directory}/key.pem"
        "ldap-certificate:${config.security.acme.certs.${ldapHost}.directory}/fullchain.pem"
        "ldap-outpost-token:${config.sops.secrets."services/authentik/ldap/outposts/mail-directory/token".path}"
        # keep-sorted end
      ];
  };
}
