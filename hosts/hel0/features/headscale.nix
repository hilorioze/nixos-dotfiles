{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  cfg = config.services.headscale;

  tailnetServerNodeNames = [
    # keep-sorted start
    "de0"
    "fakesynology"
    "fakesynology-nixos"
    "hel0"
    "hilonix"
    "lelonix"
    "zikkkix"
    # keep-sorted end
  ];
in {
  sops.secrets = {
    # to generate preauth-key:
    #
    # prefix=$(head -c 12 /dev/urandom | base64 -w0 | tr '+/' '-_' | tr -d '=' | head -c 12)
    # secret=$(head -c 64 /dev/urandom | base64 -w0 | tr '+/' '-_' | tr -d '=' | head -c 64)
    #
    # hash=$(, htpasswd -bnBC 10 "" "$secret" | cut -d: -f2)
    #
    # printf 'hskey-auth-%s-%s\n' "$prefix" "$secret"
    # printf 'prefix: %s\nbcrypt-hash: %s\n' "$prefix" "$hash"

    # keep-sorted start
    "services/headscale/control-plane/private-key".owner = config.services.headscale.user;
    "services/headscale/derp/private-key".owner = config.services.headscale.user;
    "services/headscale/preauth-keys/alex/bcrypt-hash" = {};
    "services/headscale/preauth-keys/alex/prefix" = {};
    "services/headscale/preauth-keys/de0/bcrypt-hash" = {};
    "services/headscale/preauth-keys/de0/prefix" = {};
    "services/headscale/preauth-keys/deployer/bcrypt-hash" = {};
    "services/headscale/preauth-keys/deployer/prefix" = {};
    "services/headscale/preauth-keys/fakesynology-nixos/bcrypt-hash" = {};
    "services/headscale/preauth-keys/fakesynology-nixos/prefix" = {};
    "services/headscale/preauth-keys/fakesynology/bcrypt-hash" = {};
    "services/headscale/preauth-keys/fakesynology/prefix" = {};
    "services/headscale/preauth-keys/guests/bcrypt-hash" = {};
    "services/headscale/preauth-keys/guests/prefix" = {};
    "services/headscale/preauth-keys/hel0/bcrypt-hash" = {};
    "services/headscale/preauth-keys/hel0/prefix" = {};
    "services/headscale/preauth-keys/hilonix/bcrypt-hash" = {};
    "services/headscale/preauth-keys/hilonix/prefix" = {};
    "services/headscale/preauth-keys/lelonix/bcrypt-hash" = {};
    "services/headscale/preauth-keys/lelonix/prefix" = {};
    "services/headscale/preauth-keys/philone/bcrypt-hash" = {};
    "services/headscale/preauth-keys/philone/prefix" = {};
    "services/headscale/preauth-keys/zikkkix/bcrypt-hash" = {};
    "services/headscale/preauth-keys/zikkkix/prefix" = {};
    # keep-sorted end
  };

  networking.firewall.allowedUDPPorts = [3478];

  services = {
    pdns-recursor = {
      # headscale assigns .1 to the first node so the first node is the control plane (hel0)
      dns.address = [
        "100.64.0.1"
        "fd7a:115c:a1e0::1"
      ];

      forwardZonesRecurse.internal = "100.100.100.100"; # forward `.internal` zone lookups to magicdns

      luaConfig = ''addNTA("internal")''; # magicdns does not support dnssec

      settings.recursor.lua_dns_script = pkgs.replaceVars ./headscale-pdns-recursor-cname-rewrite.lua.in {
        TAILNET_SERVER_NODE_NAMES = lib.concatStringsSep "\n" (map (nodeName: "  [\"${nodeName}\"] = true,") tailnetServerNodeNames);

        HEADSCALE_CONTROL_PLANE_HOST_NAME = lib.head (lib.splitString "." (lib.removePrefix "https://" cfg.settings.server_url));
      };
    };

    headscale = {
      enable = true;

      settings = {
        server_url = "https://hs.${config.networking.domain}";

        noise.private_key_path = config.sops.secrets."services/headscale/control-plane/private-key".path;

        policy.path = pkgs.writeText "policy.hujson" (builtins.toJSON {
          groups = {
            # keep-sorted start
            "group:guests" = ["guests@"];
            "group:home" = ["home@"];
            "group:servers" = ["servers@"];
            # keep-sorted end
          };

          tagOwners = {
            # keep-sorted start
            "tag:de0" = [];
            "tag:deployer" = [];
            "tag:fakesynology" = [];
            "tag:fakesynology-nixos" = [];
            "tag:hel0" = [];
            "tag:hilonix" = [];
            "tag:lelonix" = [];
            "tag:zikkkix" = [];
            # keep-sorted end
          };

          acls = [
            # all clients can reach `hel0` on port 53 for split dns
            {
              action = "accept";

              src = ["*"];

              dst = ["tag:hel0:53"];
            }

            # everyone can reach everyone on port 4444
            {
              action = "accept";

              src = ["*"];

              dst = ["*:4444"];
            }

            # de0 (prometheus, gatus) scrapes node-exporter on other hosts
            {
              action = "accept";

              src = ["tag:de0"];

              dst = [
                # keep-sorted start
                "tag:fakesynology-nixos:9100"
                "tag:hel0:9100"
                # keep-sorted end
              ];
            }

            # `de0` (`prometheus`) scrapes `snmp-exporter` on `fakesynology`
            {
              action = "accept";

              src = ["tag:de0"];

              dst = ["tag:fakesynology:9116"];
            }

            # de0 (gatus) checks endpoints health via https
            {
              action = "accept";

              src = ["tag:de0"];

              dst = [
                # keep-sorted start
                "tag:fakesynology-nixos:443"
                "tag:hel0:443"
                # keep-sorted end
              ];
            }

            # `de0` (`gatus`) checks `mailserver` health on `hel0`
            {
              action = "accept";

              src = ["tag:de0"];

              dst = [
                # keep-sorted start
                "tag:hel0:4190"
                "tag:hel0:465"
                "tag:hel0:993"
                # keep-sorted end
              ];
            }

            # de0 can reach the goldsrc proxies on hel0 for gatus health checks
            {
              action = "accept";

              src = ["tag:de0"];

              dst = [
                # keep-sorted start
                "tag:hel0:27015"
                "tag:hel0:28255"
                # keep-sorted end
              ];
            }

            # fluent-bit on all monitored hosts pushes logs to loki on de0
            {
              action = "accept";

              src = [
                # keep-sorted start
                "tag:fakesynology-nixos"
                "tag:hel0"
                # keep-sorted end
              ];

              dst = ["tag:de0:3100"];
            }

            # home devices can reach all nodes and internet via exit nodes
            {
              action = "accept";

              src = ["group:home" "tag:hilonix" "tag:lelonix" "tag:zikkkix"];

              dst = [
                # keep-sorted start
                "*:*"
                "autogroup:internet:*"
                # keep-sorted end
              ];
            }

            # guests can reach other guests, hilonix and lelonix
            {
              action = "accept";

              src = ["group:guests"];

              dst = [
                # keep-sorted start
                "group:guests:*"
                "tag:hilonix:*"
                "tag:lelonix:*"
                # keep-sorted end
              ];
            }

            # deployer can SSH to all deployable nodes
            {
              action = "accept";

              src = ["tag:deployer"];

              dst = [
                # keep-sorted start
                "group:servers:22"
                "tag:de0:22"
                "tag:fakesynology-nixos:22"
                "tag:hel0:22"
                "tag:hilonix:22"
                "tag:lelonix:22"
                "tag:zikkkix:22"
                # keep-sorted end
              ];
            }

            # everyone can reach niks3 on de0 over https
            {
              action = "accept";

              src = ["*"];

              dst = ["tag:de0:443"];
            }

            # everyone can reach `factorio` server on `hel0`
            {
              action = "accept";

              src = ["*"];

              dst = ["tag:hel0:${toString config.services.factorio.port}"];
            }

            # `de0` can reach `fakesynology` to expose it publicly
            {
              action = "accept";

              src = ["tag:de0"];

              dst = ["tag:fakesynology:80" "tag:fakesynology:443" "tag:fakesynology:5000" "tag:fakesynology:5001"];
            }
          ];

          autoApprovers.exitNode = [
            # keep-sorted start
            "tag:de0"
            "tag:fakesynology-nixos"
            "tag:hel0"
            # keep-sorted end
          ];
        });

        derp.server = {
          enabled = true;

          region_id = 999;
          region_code = "hs-hel0";
          region_name = "Headscale Helsinki";

          stun_listen_addr = "0.0.0.0:3478";

          private_key_path = config.sops.secrets."services/headscale/derp/private-key".path;
        };

        dns = {
          base_domain = "internal";

          # use the control plane's pdns-recursor
          nameservers.split."hilorioze.com" = [
            "100.64.0.1"
            "fd7a:115c:a1e0::1"
          ];

          # don't set headscale as the client's default resolver; only `hilorioze.com` uses split dns
          override_local_dns = false;
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.headscale = {
        entryPoints = ["https"];
        rule = "Host(`hs.${config.networking.domain}`)";

        service = "headscale";
      };

      services.headscale.loadBalancer.servers = [{url = "http://127.0.0.1:${toString cfg.port}";}];
    };
  };

  systemd.services = {
    headscale = {
      after = ["sops-nix.service"];

      wants = ["sops-nix.service"];
    };

    headscale-setup = {
      wantedBy = ["multi-user.target"];
      after = [
        # keep-sorted start
        "headscale.service"
        "sops-nix.service"
        # keep-sorted end
      ];

      wants = ["sops-nix.service"];
      requires = ["headscale.service"];

      serviceConfig = {
        Type = "oneshot";

        RemainAfterExit = "yes";
      };

      script = ''
        headscale_cmd="${lib.getExe cfg.package} --config ${cfg.configFile}"
        sqlite_cmd="${lib.getExe pkgs.sqlite} ${cfg.settings.database.sqlite.path}"

        ensure_user() {
          local user_name="$1"

          local user_json=$($headscale_cmd users list -o json --name "$user_name" 2>/dev/null)

          if [ -n "$user_json" ] && [ "$user_json" != "[]" ]; then
            echo "$user_json" | ${lib.getExe pkgs.jq} -r '.[0].id'
          else
            $headscale_cmd users create "$user_name" -o json 2>/dev/null | ${lib.getExe pkgs.jq} -r '.id'
          fi
        }

        # keep-sorted start
        deployer_id=$(ensure_user deployer)
        guests_id=$(ensure_user guests)
        home_id=$(ensure_user home)
        servers_id=$(ensure_user servers)
        # keep-sorted end

        reconcile_preauth_key() {
          local user_id="$1"
          local preauth_key_prefix_path="$2"
          local preauth_key_hash_path="$3"
          local node_tags="''${4:-[]}"
          local is_preauth_key_reusable="''${5:-0}"
          local is_node_ephemeral="''${6:-0}" # if set then nodes registered through this key become ephemeral (auto-deleted after 2 min offline)

          local preauth_key_prefix=$(cat "$preauth_key_prefix_path")
          local preauth_key_hash=$(cat "$preauth_key_hash_path")

          local preauth_key_exists=$($sqlite_cmd "SELECT EXISTS(SELECT 1 FROM pre_auth_keys WHERE prefix = '$preauth_key_prefix' LIMIT 1)")

          if [ "$preauth_key_exists" = "1" ]; then
            $sqlite_cmd "UPDATE pre_auth_keys SET hash = '$preauth_key_hash', user_id = $user_id, reusable = $is_preauth_key_reusable, ephemeral = $is_node_ephemeral, tags = '$node_tags' WHERE prefix = '$preauth_key_prefix'"
          else
            $sqlite_cmd "INSERT INTO pre_auth_keys (key, prefix, hash, user_id, reusable, ephemeral, tags, created_at) VALUES (NULL, '$preauth_key_prefix', '$preauth_key_hash', $user_id, $is_preauth_key_reusable, $is_node_ephemeral, '$node_tags', datetime('now'))"
          fi

          $sqlite_cmd "SELECT id FROM pre_auth_keys WHERE prefix = '$preauth_key_prefix' LIMIT 1"
        }

        # keep-sorted start block=yes newline_separated=true by_regex=services/headscale/([^/]+)/
        alex_key_id=$(reconcile_preauth_key "$home_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/alex/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/alex/bcrypt-hash".path})

        de0_key_id=$(reconcile_preauth_key "$servers_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/de0/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/de0/bcrypt-hash".path} \
          '["tag:de0"]')

        deployer_key_id=$(reconcile_preauth_key "$deployer_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/deployer/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/deployer/bcrypt-hash".path} \
          '["tag:deployer"]' \
          1 \
          1) # reusable and ephemeral (for ephemeral CI runners)

        fakesynology_key_id=$(reconcile_preauth_key "$servers_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/fakesynology/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/fakesynology/bcrypt-hash".path} \
          '["tag:fakesynology"]')

        fakesynology_nixos_key_id=$(reconcile_preauth_key "$servers_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/fakesynology-nixos/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/fakesynology-nixos/bcrypt-hash".path} \
          '["tag:fakesynology-nixos"]')

        guests_key_id=$(reconcile_preauth_key "$guests_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/guests/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/guests/bcrypt-hash".path} \
          '[]' \
          1 \
          1) # reusable and ephemeral (no stale device accumulation)

        hel0_key_id=$(reconcile_preauth_key "$servers_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/hel0/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/hel0/bcrypt-hash".path} \
          '["tag:hel0"]')

        hilonix_key_id=$(reconcile_preauth_key "$home_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/hilonix/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/hilonix/bcrypt-hash".path} \
          '["tag:hilonix"]')

        lelonix_key_id=$(reconcile_preauth_key "$home_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/lelonix/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/lelonix/bcrypt-hash".path} \
          '["tag:lelonix"]')

        philone_key_id=$(reconcile_preauth_key "$home_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/philone/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/philone/bcrypt-hash".path})

        zikkkix_key_id=$(reconcile_preauth_key "$home_id" \
          ${config.sops.secrets."services/headscale/preauth-keys/zikkkix/prefix".path} \
          ${config.sops.secrets."services/headscale/preauth-keys/zikkkix/bcrypt-hash".path} \
          '["tag:zikkkix"]')
        # keep-sorted end

        ensure_preauth_key_used() {
          local key_id="$1"

          local node_exists=$($sqlite_cmd "SELECT EXISTS(SELECT 1 FROM nodes WHERE auth_key_id = '$key_id' LIMIT 1)")

          if [ "$node_exists" = "1" ]; then
            $sqlite_cmd "UPDATE pre_auth_keys SET used = 1 WHERE id = '$key_id' AND used = 0"
          fi
        }

        # mark preauth keys as used if nodes are already registered via them
        # keep-sorted start
        ensure_preauth_key_used "$alex_key_id"
        ensure_preauth_key_used "$de0_key_id"
        ensure_preauth_key_used "$fakesynology_key_id"
        ensure_preauth_key_used "$fakesynology_nixos_key_id"
        ensure_preauth_key_used "$hel0_key_id"
        ensure_preauth_key_used "$hilonix_key_id"
        ensure_preauth_key_used "$lelonix_key_id"
        ensure_preauth_key_used "$philone_key_id"
        ensure_preauth_key_used "$zikkkix_key_id"
        # keep-sorted end

        get_node_id_by_key_id() {
          local key_id="$1"

          $sqlite_cmd "SELECT nodes.id FROM nodes WHERE auth_key_id = '$key_id' LIMIT 1"
        }

        # keep-sorted start
        alex_node_id=$(get_node_id_by_key_id "$alex_key_id")
        de0_node_id=$(get_node_id_by_key_id "$de0_key_id")
        fakesynology_nixos_node_id=$(get_node_id_by_key_id "$fakesynology_nixos_key_id")
        fakesynology_node_id=$(get_node_id_by_key_id "$fakesynology_key_id")
        hel0_node_id=$(get_node_id_by_key_id "$hel0_key_id")
        hilonix_node_id=$(get_node_id_by_key_id "$hilonix_key_id")
        lelonix_node_id=$(get_node_id_by_key_id "$lelonix_key_id")
        zikkkix_node_id=$(get_node_id_by_key_id "$zikkkix_key_id")
        # keep-sorted end

        set_node_tags_by_node_id() {
          local node_id="$1"
          shift

          if [ -n "$node_id" ]; then
            $headscale_cmd nodes tag -i "$node_id" -t "$@"
          fi
        }

        # ensure tags for already-registered nodes (preauth key tags only apply at registration time)
        # keep-sorted start
        set_node_tags_by_node_id "$de0_node_id" "tag:de0"
        set_node_tags_by_node_id "$fakesynology_nixos_node_id" "tag:fakesynology-nixos"
        set_node_tags_by_node_id "$fakesynology_node_id" "tag:fakesynology"
        set_node_tags_by_node_id "$hel0_node_id" "tag:hel0"
        set_node_tags_by_node_id "$hilonix_node_id" "tag:hilonix"
        set_node_tags_by_node_id "$lelonix_node_id" "tag:lelonix"
        set_node_tags_by_node_id "$zikkkix_node_id" "tag:zikkkix"
        # keep-sorted end

        rename_node_by_node_id() {
          local node_id="$1"
          local new_node_name="$2"

          if [ -n "$node_id" ]; then
            $headscale_cmd nodes rename -i "$node_id" "$new_node_name"
          fi
        }

        rename_node_by_node_id "$alex_node_id" "alex" # iOS sends "localhost" as hostname; rename to the desired name
      '';
    };
  };
}
