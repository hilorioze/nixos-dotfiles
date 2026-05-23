# AI-generated NixOS module adding multi-instance support to hermes-agent, adapted from https://github.com/NousResearch/hermes-agent/blob/9eaddfafa30018b1d4eb3e5e72bbe2d242f8e50e/nix/nixosModules.nix
{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  # Deep-merge config type (from 0xrsydn/nix-hermes-agent)
  deepConfigType = lib.types.mkOptionType {
    name = "hermes-config-attrs";
    description = "Hermes YAML config (attrset), merged deeply via lib.recursiveUpdate.";
    check = builtins.isAttrs;
    merge = _loc: defs: lib.foldl' lib.recursiveUpdate {} (map (d: d.value) defs);
  };

  configMergeScript = pkgs.callPackage "${inputs.hermes-agent}/nix/configMergeScript.nix" {};

  hermes-agent = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Runs as root inside the container on every start. Provisions the
  # hermes user + sudo on first boot (writable layer persists), then
  # drops privileges. Supports arbitrary base images (Debian, Alpine, etc).
  containerEntrypoint = pkgs.writeShellScript "hermes-container-entrypoint" ''
    set -eu

    HERMES_UID="''${HERMES_UID:?HERMES_UID must be set}"
    HERMES_GID="''${HERMES_GID:?HERMES_GID must be set}"

    # ── Group: ensure a group with GID=$HERMES_GID exists ──
    # Check by GID (not name) to avoid collisions with pre-existing groups
    # (e.g. GID 100 = "users" on Ubuntu)
    EXISTING_GROUP=$(getent group "$HERMES_GID" 2>/dev/null | cut -d: -f1 || true)
    if [ -n "$EXISTING_GROUP" ]; then
      GROUP_NAME="$EXISTING_GROUP"
    else
      GROUP_NAME="hermes"
      if command -v groupadd >/dev/null 2>&1; then
        groupadd -g "$HERMES_GID" "$GROUP_NAME"
      elif command -v addgroup >/dev/null 2>&1; then
        addgroup -g "$HERMES_GID" "$GROUP_NAME" 2>/dev/null || true
      fi
    fi

    # ── User: ensure a user with UID=$HERMES_UID exists ──
    PASSWD_ENTRY=$(getent passwd "$HERMES_UID" 2>/dev/null || true)
    if [ -n "$PASSWD_ENTRY" ]; then
      TARGET_USER=$(echo "$PASSWD_ENTRY" | cut -d: -f1)
      TARGET_HOME=$(echo "$PASSWD_ENTRY" | cut -d: -f6)
    else
      TARGET_USER="hermes"
      TARGET_HOME="/home/hermes"
      if command -v useradd >/dev/null 2>&1; then
        useradd -u "$HERMES_UID" -g "$HERMES_GID" -m -d "$TARGET_HOME" -s /bin/bash "$TARGET_USER"
      elif command -v adduser >/dev/null 2>&1; then
        adduser -u "$HERMES_UID" -D -h "$TARGET_HOME" -s /bin/sh -G "$GROUP_NAME" "$TARGET_USER" 2>/dev/null || true
      fi
    fi
    mkdir -p "$TARGET_HOME"
    chown "$HERMES_UID:$HERMES_GID" "$TARGET_HOME"
    chmod 0750 "$TARGET_HOME"

    # Ensure HERMES_HOME is owned by the target user
    if [ -n "''${HERMES_HOME:-}" ] && [ -d "$HERMES_HOME" ]; then
      chown -R "$HERMES_UID:$HERMES_GID" "$HERMES_HOME"
    fi

    # ── Provision apt packages (first boot only, cached in writable layer) ──
    # sudo: agent self-modification
    # nodejs/npm: writable node so npm i -g works (nix store copies are read-only)
    #   Node 22 via NodeSource — Ubuntu 24.04 ships Node 18 which is EOL.
    # curl: needed for uv installer + NodeSource setup
    if [ ! -f /var/lib/hermes-tools-provisioned ] && command -v apt-get >/dev/null 2>&1; then
      echo "First boot: provisioning agent tools..."
      apt-get update -qq
      apt-get install -y -qq sudo curl ca-certificates gnupg
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
      echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
      apt-get update -qq
      apt-get install -y -qq nodejs
      touch /var/lib/hermes-tools-provisioned
    fi

    if command -v sudo >/dev/null 2>&1 && [ ! -f /etc/sudoers.d/hermes ]; then
      mkdir -p /etc/sudoers.d
      echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hermes
      chmod 0440 /etc/sudoers.d/hermes
    fi

    # uv (Python manager) — not in Ubuntu repos, retry-safe outside the sentinel
    if ! command -v uv >/dev/null 2>&1 && [ ! -x "$TARGET_HOME/.local/bin/uv" ] && command -v curl >/dev/null 2>&1; then
      su -s /bin/sh "$TARGET_USER" -c 'curl -LsSf https://astral.sh/uv/install.sh | sh' || true
    fi

    # Python 3.12 venv — gives the agent a writable Python with pip.
    # --seed includes pip/setuptools so bare `pip install` works.
    _UV_BIN="$TARGET_HOME/.local/bin/uv"
    if [ ! -d "$TARGET_HOME/.venv" ] && [ -x "$_UV_BIN" ]; then
      su -s /bin/sh "$TARGET_USER" -c "
        export PATH=\"\$HOME/.local/bin:\$PATH\"
        uv python install 3.12
        uv venv --python 3.12 --seed \"\$HOME/.venv\"
      " || true
    fi

    # Put the agent venv first on PATH so python/pip resolve to writable copies
    if [ -d "$TARGET_HOME/.venv/bin" ]; then
      export PATH="$TARGET_HOME/.venv/bin:$PATH"
    fi

    if command -v setpriv >/dev/null 2>&1; then
      exec setpriv --reuid="$HERMES_UID" --regid="$HERMES_GID" --init-groups "$@"
    elif command -v su >/dev/null 2>&1; then
      exec su -s /bin/sh "$TARGET_USER" -c 'exec "$0" "$@"' -- "$@"
    else
      echo "WARNING: no privilege-drop tool (setpriv/su), running as root" >&2
      exec "$@"
    fi
  '';

  # ── Instance submodule ──────────────────────────────────────────────

  instanceModule = {
    name,
    config,
    ...
  }:
    with lib; {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable this Hermes Agent instance.";
        };

        # ── Package ──────────────────────────────────────────────────────────
        package = mkOption {
          type = types.package;
          default = hermes-agent;
          defaultText = literalExpression "inputs.hermes-agent.packages.\${system}.default";
          description = "The hermes-agent package to use.";
        };

        # ── Service identity ─────────────────────────────────────────────────
        user = mkOption {
          type = types.str;
          default = "hermes-${name}";
          description = "System user running the gateway.";
        };

        group = mkOption {
          type = types.str;
          default = "hermes-${name}";
          description = "System group running the gateway.";
        };

        createUser = mkOption {
          type = types.bool;
          default = true;
          description = "Create the user/group automatically.";
        };

        # ── Directories ──────────────────────────────────────────────────────
        stateDir = mkOption {
          type = types.str;
          default = "/var/lib/hermes-${name}";
          description = "State directory. Contains .hermes/ subdir (HERMES_HOME).";
        };

        workingDirectory = mkOption {
          type = types.str;
          default = "${config.stateDir}/workspace";
          defaultText = literalExpression ''"''${config.stateDir}/workspace"'';
          description = "Working directory for the agent (terminal.cwd).";
        };

        # ── Declarative config ───────────────────────────────────────────────
        configFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path to an existing config.yaml. If set, takes precedence over
            the declarative `settings` option.
          '';
        };

        settings = mkOption {
          type = deepConfigType;
          default = {};
          description = ''
            Declarative Hermes config (attrset). Deep-merged across module
            definitions and rendered as config.yaml.
          '';
          example = literalExpression ''
            {
              model = "anthropic/claude-sonnet-4";
              terminal.backend = "local";
              compression = { enabled = true; threshold = 0.85; };
              toolsets = [ "all" ];
            }
          '';
        };

        # ── Secrets / environment ────────────────────────────────────────────
        environmentFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''
            Paths to environment files containing secrets (API keys, tokens).
            Contents are merged into $HERMES_HOME/.env at activation time.
            Hermes reads this file on every startup via load_hermes_dotenv().
          '';
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = ''
            Non-secret environment variables. Merged into $HERMES_HOME/.env
            at activation time. Do NOT put secrets here — use environmentFiles.
          '';
        };

        authFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path to an auth.json seed file (OAuth credentials).
            Only copied on first deploy — existing auth.json is preserved.
          '';
        };

        authFileForceOverwrite = mkOption {
          type = types.bool;
          default = false;
          description = "Always overwrite auth.json from authFile on activation.";
        };

        # ── Documents ────────────────────────────────────────────────────────
        documents = mkOption {
          type = types.attrsOf (types.either types.str types.path);
          default = {};
          description = ''
            Workspace files (SOUL.md, USER.md, etc.). Keys are filenames,
            values are inline strings or paths. Installed into workingDirectory.
          '';
          example = literalExpression ''
            {
              "SOUL.md" = "You are a helpful AI assistant.";
              "USER.md" = ./documents/USER.md;
            }
          '';
        };

        # ── MCP Servers ──────────────────────────────────────────────────────
        mcpServers = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              # Stdio transport
              command = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "MCP server command (stdio transport).";
              };
              args = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "Command-line arguments (stdio transport).";
              };
              env = mkOption {
                type = types.attrsOf types.str;
                default = {};
                description = "Environment variables for the server process (stdio transport).";
              };

              # HTTP/StreamableHTTP transport
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "MCP server endpoint URL (HTTP/StreamableHTTP transport).";
              };
              headers = mkOption {
                type = types.attrsOf types.str;
                default = {};
                description = "HTTP headers, e.g. for authentication (HTTP transport).";
              };

              # Authentication
              auth = mkOption {
                type = types.nullOr (types.enum ["oauth"]);
                default = null;
                description = ''
                  Authentication method. Set to "oauth" for OAuth 2.1 PKCE flow
                  (remote MCP servers). Tokens are stored in $HERMES_HOME/mcp-tokens/.
                '';
              };

              # Enable/disable
              enabled = mkOption {
                type = types.bool;
                default = true;
                description = "Enable or disable this MCP server.";
              };

              # Common options
              timeout = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Tool call timeout in seconds (default: 120).";
              };
              connect_timeout = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Initial connection timeout in seconds (default: 60).";
              };

              # Tool filtering
              tools = mkOption {
                type = types.nullOr (types.submodule {
                  options = {
                    include = mkOption {
                      type = types.listOf types.str;
                      default = [];
                      description = "Tool allowlist — only these tools are registered.";
                    };
                    exclude = mkOption {
                      type = types.listOf types.str;
                      default = [];
                      description = "Tool blocklist — these tools are hidden.";
                    };
                  };
                });
                default = null;
                description = "Filter which tools are exposed by this server.";
              };

              # Sampling (server-initiated LLM requests)
              sampling = mkOption {
                type = types.nullOr (types.submodule {
                  options = {
                    enabled = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Enable sampling.";
                    };
                    model = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Override model for sampling requests.";
                    };
                    max_tokens_cap = mkOption {
                      type = types.nullOr types.int;
                      default = null;
                      description = "Max tokens per request.";
                    };
                    timeout = mkOption {
                      type = types.nullOr types.int;
                      default = null;
                      description = "LLM call timeout in seconds.";
                    };
                    max_rpm = mkOption {
                      type = types.nullOr types.int;
                      default = null;
                      description = "Max requests per minute.";
                    };
                    max_tool_rounds = mkOption {
                      type = types.nullOr types.int;
                      default = null;
                      description = "Max tool-use rounds per sampling request.";
                    };
                    allowed_models = mkOption {
                      type = types.listOf types.str;
                      default = [];
                      description = "Models the server is allowed to request.";
                    };
                    log_level = mkOption {
                      type = types.nullOr (types.enum ["debug" "info" "warning"]);
                      default = null;
                      description = "Audit log level for sampling requests.";
                    };
                  };
                });
                default = null;
                description = "Sampling configuration for server-initiated LLM requests.";
              };
            };
          });
          default = {};
          description = ''
            MCP server configurations (merged into settings.mcp_servers).
            Each server uses either stdio (command/args) or HTTP (url) transport.
          '';
          example = literalExpression ''
            {
              filesystem = {
                command = "npx";
                args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/user" ];
              };
              remote-api = {
                url = "http://my-server:8080/v0/mcp";
                headers = { Authorization = "Bearer ..."; };
              };
              remote-oauth = {
                url = "https://mcp.example.com/mcp";
                auth = "oauth";
              };
            }
          '';
        };

        # ── Service behavior ─────────────────────────────────────────────────
        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Extra command-line arguments for `hermes gateway`.";
        };

        extraPackages = mkOption {
          type = types.listOf types.package;
          default = [];
          description = ''
            Extra packages available to the agent — terminal commands, skills,
            cron jobs, and the service process all see them.

            Implemented via the hermes user's per-user profile
            (`/etc/profiles/per-user/${config.user}/bin`), which NixOS includes
            in PATH for login shells.  The packages are also added to the
            systemd service PATH for direct process access.
          '';
        };

        extraPlugins = mkOption {
          type = types.listOf types.package;
          default = [];
          description = ''
            Directory-based plugin packages to symlink into the hermes plugins
            directory. Each package should contain a plugin.yaml and __init__.py
            at its root. Hermes discovers these automatically on startup.
          '';
          example = literalExpression ''
            [
              (pkgs.fetchFromGitHub {
                owner = "stephenschoettler";
                repo = "hermes-lcm";
                name = "hermes-lcm";
                rev = "v0.7.0";
                hash = "sha256-...";
              })
            ]
          '';
        };

        extraPythonPackages = mkOption {
          type = types.listOf types.package;
          default = [];
          description = ''
            Python packages to add to PYTHONPATH for entry-point plugin discovery.
            These are pip-packaged plugins that register via the
            hermes_agent.plugins entry-point group. Each package must be built
            with the same Python interpreter as hermes (python312).
          '';
          example = literalExpression ''
            [
              (pkgs.python312Packages.buildPythonPackage {
                pname = "rtk-hermes";
                version = "1.0.0";
                src = pkgs.fetchFromGitHub {
                  owner = "ogallotti";
                  repo = "rtk-hermes";
                  rev = "main";
                  hash = "sha256-...";
                };
              })
            ]
          '';
        };

        restart = mkOption {
          type = types.str;
          default = "always";
          description = "systemd Restart= policy.";
        };

        restartSec = mkOption {
          type = types.int;
          default = 5;
          description = "systemd RestartSec= value.";
        };

        # ── OCI Container (opt-in) ──────────────────────────────────────────
        container = {
          enable = mkEnableOption "OCI container mode (Ubuntu base, full self-modification support)";

          backend = mkOption {
            type = types.enum ["docker" "podman"];
            default = "docker";
            description = "Container runtime.";
          };

          extraVolumes = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Extra volume mounts (host:container:mode format).";
            example = ["/home/user/projects:/projects:rw"];
          };

          extraOptions = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Extra arguments passed to docker/podman run.";
          };

          image = mkOption {
            type = types.str;
            default = "ubuntu:24.04";
            description = "OCI container image. The container pulls this at runtime via Docker/Podman.";
          };

          hostUsers = mkOption {
            type = types.listOf types.str;
            default = [];
            description = ''
              Interactive users who get a ~/.hermes symlink to the service
              stateDir. These users are automatically added to the instance's group.
            '';
            example = ["sidbin"];
          };
        };
      };

      # ── Merge MCP servers into settings ────────────────────────────────
      config = mkIf (config.mcpServers != {}) {
        settings.mcp_servers =
          lib.mapAttrs (
            _srvName: srv:
            # Stdio transport
              lib.optionalAttrs (srv.command != null) {inherit (srv) command args;}
              // lib.optionalAttrs (srv.env != {}) {inherit (srv) env;}
              # HTTP transport
              // lib.optionalAttrs (srv.url != null) {inherit (srv) url;}
              // lib.optionalAttrs (srv.headers != {}) {inherit (srv) headers;}
              # Auth
              // lib.optionalAttrs (srv.auth != null) {inherit (srv) auth;}
              # Enable/disable
              // {inherit (srv) enabled;}
              # Common options
              // lib.optionalAttrs (srv.timeout != null) {inherit (srv) timeout;}
              // lib.optionalAttrs (srv.connect_timeout != null) {inherit (srv) connect_timeout;}
              # Tool filtering
              // lib.optionalAttrs (srv.tools != null) {
                tools = lib.filterAttrs (_: v: v != []) {
                  inherit (srv.tools) include exclude;
                };
              }
              # Sampling
              // lib.optionalAttrs (srv.sampling != null) {
                sampling = lib.filterAttrs (_: v: v != null && v != []) {
                  inherit
                    (srv.sampling)
                    enabled
                    model
                    max_tokens_cap
                    timeout
                    max_rpm
                    max_tool_rounds
                    allowed_models
                    log_level
                    ;
                };
              }
          )
          config.mcpServers;
      };
    };

  # ── Per-instance context (shared computations) ─────────────────────────
  mkCtx = name: icfg: let
    effectivePackage =
      if icfg.extraPythonPackages == []
      then icfg.package
      else icfg.package.override {inherit (icfg) extraPythonPackages;};

    computedSettings = lib.recursiveUpdate {terminal.cwd = icfg.workingDirectory;} icfg.settings;
    configJson = builtins.toJSON computedSettings;
    generatedConfigFile = pkgs.writeText "hermes-config-${name}.yaml" configJson;
    configFile =
      if icfg.configFile != null
      then icfg.configFile
      else generatedConfigFile;

    envFileContent = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "${k}=${v}") icfg.environment
    );
    envFile = pkgs.writeText "hermes-env-${name}" envFileContent;
    documentDerivation = pkgs.runCommand "hermes-documents-${name}" {} (
      ''
        mkdir -p $out
      ''
      + lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          docName: value:
            if builtins.isPath value || lib.isStorePath value
            then "cp ${value} $out/${docName}"
            else "cat > $out/${docName} <<'HERMES_DOC_EOF'\n${value}\nHERMES_DOC_EOF"
        )
        icfg.documents
      )
    );

    containerName = "hermes-agent-${name}";
    containerDataDir = "/data";
    containerHomeDir = "/home/hermes";

    containerBin =
      if icfg.container.backend == "docker"
      then "${pkgs.docker}/bin/docker"
      else "${pkgs.podman}/bin/podman";

    containerIdentity = builtins.hashString "sha256" (builtins.toJSON {
      schema = 4;
      inherit (icfg.container) image;
      inherit (icfg.container) extraVolumes;
      inherit (icfg.container) extraOptions;
    });

    identityFile = "${icfg.stateDir}/.container-identity";

    containerWorkDir =
      if lib.hasPrefix "${icfg.stateDir}/" icfg.workingDirectory
      then "${containerDataDir}/${lib.removePrefix "${icfg.stateDir}/" icfg.workingDirectory}"
      else icfg.workingDirectory;
  in {
    inherit
      name
      icfg
      effectivePackage
      configJson
      generatedConfigFile
      configFile
      envFileContent
      envFile
      documentDerivation
      containerName
      containerDataDir
      containerHomeDir
      containerBin
      containerIdentity
      identityFile
      containerWorkDir
      ;
  };
in {
  options.services.hermes-agent.instances = with lib;
    mkOption {
      type = types.attrsOf (types.submodule instanceModule);
      default = {};
      description = ''
        Multi-instance configuration for Hermes Agent. Each attribute
        defines a separate instance with its own user, state directory,
        systemd service, and configuration.
      '';
    };

  # ── Static top-level keys break the infinite-recursion cycle ────────
  # The module system can determine which option paths our config
  # contributes to (users, systemd, assertions, warnings, system,
  # virtualisation) WITHOUT evaluating any values.  This lets it compute
  # config.services.hermes-agent.instances from user definitions alone,
  # so the lazy values below can safely read it later.
  config = let
    inherit (config.services.hermes-agent) instances;
  in {
    users = lib.mkMerge (lib.mapAttrsToList (_name: icfg:
      lib.mkIf icfg.enable (lib.mkMerge [
        (lib.mkIf icfg.createUser {
          groups.${icfg.group} = {};
          users.${icfg.user} = {
            isSystemUser = true;
            inherit (icfg) group;
            home = icfg.stateDir;
            createHome = true;
            shell = pkgs.bashInteractive;
          };
        })
        (lib.mkIf (icfg.container.enable && icfg.container.hostUsers != []) {
          users = lib.genAttrs icfg.container.hostUsers (_user: {
            extraGroups = [icfg.group];
          });
        })
        (lib.mkIf (icfg.extraPackages != []) {
          users.${icfg.user}.packages = icfg.extraPackages;
        })
      ]))
    instances);

    assertions = lib.concatLists (lib.mapAttrsToList (
        name: icfg:
          if icfg.enable
          then let
            names = map lib.getName icfg.extraPlugins;
          in [
            {
              assertion = (lib.length names) == (lib.length (lib.unique names));
              message = "services.hermes-agent.instances.${name}.extraPlugins: duplicate plugin names detected: ${toString names}. If using fetchFromGitHub, set name = \"plugin-name\" to disambiguate.";
            }
          ]
          else []
      )
      instances);

    warnings = lib.concatLists (lib.mapAttrsToList (
        name: icfg:
          if icfg.enable && icfg.container.enable && icfg.container.hostUsers != []
          then [
            ''
              services.hermes-agent.instances.${name}: container.enable is true and
              container.hostUsers is set. Ensure hermes is on PATH so container
              routing works for interactive users.
            ''
          ]
          else []
      )
      instances);

    systemd = lib.mkMerge (lib.mapAttrsToList (name: icfg: let
      ctx = mkCtx name icfg;
    in
      lib.mkIf icfg.enable (lib.mkMerge [
        {
          tmpfiles.rules = [
            "d ${icfg.stateDir}                  2770 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.stateDir}/.hermes          2770 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.stateDir}/.hermes/cron     2770 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.stateDir}/.hermes/sessions 2770 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.stateDir}/.hermes/logs     2770 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.stateDir}/.hermes/memories 2770 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.stateDir}/.hermes/plugins  2770 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.stateDir}/home             0750 ${icfg.user} ${icfg.group} - -"
            "d ${icfg.workingDirectory}           2770 ${icfg.user} ${icfg.group} - -"
          ];
        }

        # ── Native systemd service ──────────────────────────────────────────
        (lib.mkIf (!icfg.container.enable) {
          services."hermes-agent-${name}" = {
            description = "Hermes Agent Gateway (${name})";
            wantedBy = ["multi-user.target"];
            after = ["network-online.target"];
            wants = ["network-online.target"];

            environment = {
              HOME = icfg.stateDir;
              HERMES_HOME = "${icfg.stateDir}/.hermes";
              HERMES_MANAGED = "true";
            };

            serviceConfig = {
              User = icfg.user;
              Group = icfg.group;
              WorkingDirectory = icfg.workingDirectory;

              ExecStart = lib.concatStringsSep " " ([
                  "${ctx.effectivePackage}/bin/hermes"
                  "gateway"
                ]
                ++ icfg.extraArgs);

              Restart = icfg.restart;
              RestartSec = icfg.restartSec;

              UMask = "0007";

              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ProtectHome = false;
              ReadWritePaths = [
                icfg.stateDir
                icfg.workingDirectory
              ];
              PrivateTmp = true;
            };

            path =
              [
                ctx.effectivePackage
                pkgs.bash
                pkgs.coreutils
                pkgs.git
              ]
              ++ icfg.extraPackages;
          };
        })

        # ── OCI container service ──────────────────────────────────────────
        (lib.mkIf icfg.container.enable {
          services."hermes-agent-${name}" = {
            description = "Hermes Agent Gateway (${name}, container)";
            wantedBy = ["multi-user.target"];
            after =
              ["network-online.target"]
              ++ lib.optional (icfg.container.backend == "docker") "docker.service";
            wants = ["network-online.target"];
            requires = lib.optional (icfg.container.backend == "docker") "docker.service";

            preStart = ''
              ln -sfn ${ctx.effectivePackage} ${icfg.stateDir}/current-package
              ln -sfn ${containerEntrypoint} ${icfg.stateDir}/current-entrypoint

              ${pkgs.nix}/bin/nix-store --add-root ${icfg.stateDir}/.gc-root --indirect -r ${ctx.effectivePackage} 2>/dev/null || true
              ${pkgs.nix}/bin/nix-store --add-root ${icfg.stateDir}/.gc-root-entrypoint --indirect -r ${containerEntrypoint} 2>/dev/null || true

              NEED_CREATE=false
              if ! ${ctx.containerBin} inspect ${ctx.containerName} &>/dev/null; then
                NEED_CREATE=true
              elif [ ! -f ${ctx.identityFile} ] || [ "$(cat ${ctx.identityFile})" != "${ctx.containerIdentity}" ]; then
                echo "Container config changed, recreating..."
                ${ctx.containerBin} rm -f ${ctx.containerName} || true
                NEED_CREATE=true
              fi

              if [ "$NEED_CREATE" = "true" ]; then
                HERMES_UID=$(${pkgs.coreutils}/bin/id -u ${icfg.user})
                HERMES_GID=$(${pkgs.coreutils}/bin/id -g ${icfg.user})

                echo "Creating container..."
                ${ctx.containerBin} create \
                  --name ${ctx.containerName} \
                  --network=host \
                  --entrypoint ${ctx.containerDataDir}/current-entrypoint \
                  --volume /nix/store:/nix/store:ro \
                  --volume ${icfg.stateDir}:${ctx.containerDataDir} \
                  --volume ${icfg.stateDir}/home:${ctx.containerHomeDir} \
                  ${lib.concatStringsSep " " (map (v: "--volume ${v}") icfg.container.extraVolumes)} \
                  --env HERMES_UID="$HERMES_UID" \
                  --env HERMES_GID="$HERMES_GID" \
                  --env HERMES_HOME=${ctx.containerDataDir}/.hermes \
                  --env HERMES_MANAGED=true \
                  --env HOME=${ctx.containerHomeDir} \
                  ${lib.concatStringsSep " " icfg.container.extraOptions} \
                  ${icfg.container.image} \
                  ${ctx.containerDataDir}/current-package/bin/hermes gateway run --replace ${lib.concatStringsSep " " icfg.extraArgs}

                echo "${ctx.containerIdentity}" > ${ctx.identityFile}
              fi
            '';

            script = ''
              exec ${ctx.containerBin} start -a ${ctx.containerName}
            '';

            preStop = ''
              ${ctx.containerBin} stop -t 10 ${ctx.containerName} || true
            '';

            serviceConfig = {
              Type = "simple";
              Restart = icfg.restart;
              RestartSec = icfg.restartSec;
              TimeoutStopSec = 30;
            };
          };
        })
      ]))
    instances);

    system = lib.mkMerge (lib.mapAttrsToList (name: icfg: let
      ctx = mkCtx name icfg;
    in
      lib.mkIf icfg.enable {
        activationScripts."hermes-agent-setup-${name}" = lib.stringAfter (["users"] ++ lib.optional (config.system.activationScripts ? setupSecrets) "setupSecrets") ''
          # Ensure directories exist (activation runs before tmpfiles)
          mkdir -p ${icfg.stateDir}/.hermes
          mkdir -p ${icfg.stateDir}/home
          mkdir -p ${icfg.workingDirectory}
          chown ${icfg.user}:${icfg.group} ${icfg.stateDir} ${icfg.stateDir}/.hermes ${icfg.stateDir}/home ${icfg.workingDirectory}
          chmod 2770 ${icfg.stateDir} ${icfg.stateDir}/.hermes ${icfg.workingDirectory}
          chmod 0750 ${icfg.stateDir}/home

          # Create subdirs, set setgid + group-writable, migrate existing files.
          find ${icfg.stateDir}/.hermes -maxdepth 1 \
            \( -name "*.db" -o -name "*.db-wal" -o -name "*.db-shm" -o -name "SOUL.md" \) \
            -exec chmod g+rw {} + 2>/dev/null || true
          for _subdir in cron sessions logs memories plugins; do
            mkdir -p "${icfg.stateDir}/.hermes/$_subdir"
            chown ${icfg.user}:${icfg.group} "${icfg.stateDir}/.hermes/$_subdir"
            chmod 2770 "${icfg.stateDir}/.hermes/$_subdir"
            find "${icfg.stateDir}/.hermes/$_subdir" -type f \
              -exec chmod g+rw {} + 2>/dev/null || true
          done

          # Merge Nix settings into existing config.yaml.
          ${
            if icfg.configFile != null
            then ''
              install -o ${icfg.user} -g ${icfg.group} -m 0640 -D ${ctx.configFile} ${icfg.stateDir}/.hermes/config.yaml
            ''
            else ''
              ${configMergeScript} ${ctx.generatedConfigFile} ${icfg.stateDir}/.hermes/config.yaml
              chown ${icfg.user}:${icfg.group} ${icfg.stateDir}/.hermes/config.yaml
              chmod 0640 ${icfg.stateDir}/.hermes/config.yaml
            ''
          }

          # Managed mode marker
          touch ${icfg.stateDir}/.hermes/.managed
          chown ${icfg.user}:${icfg.group} ${icfg.stateDir}/.hermes/.managed
          chmod 0644 ${icfg.stateDir}/.hermes/.managed

          # Container mode metadata
          ${
            if icfg.container.enable
            then ''
              cat > ${icfg.stateDir}/.hermes/.container-mode <<'HERMES_CONTAINER_MODE_EOF'
              # Written by NixOS activation script. Do not edit manually.
              backend=${icfg.container.backend}
              container_name=${ctx.containerName}
              exec_user=${icfg.user}
              hermes_bin=${ctx.containerDataDir}/current-package/bin/hermes
              HERMES_CONTAINER_MODE_EOF
              chown ${icfg.user}:${icfg.group} ${icfg.stateDir}/.hermes/.container-mode
              chmod 0644 ${icfg.stateDir}/.hermes/.container-mode
            ''
            else ''
              rm -f ${icfg.stateDir}/.hermes/.container-mode

              # Remove symlink bridge for hostUsers
              ${lib.concatStringsSep "\n" (map (user: let
                  userHome = config.users.users.${user}.home;
                  symlinkPath = "${userHome}/.hermes";
                in ''
                  if [ -L "${symlinkPath}" ] && [ "$(readlink "${symlinkPath}")" = "${icfg.stateDir}/.hermes" ]; then
                    rm -f "${symlinkPath}"
                    echo "hermes-agent-${name}: removed symlink ${symlinkPath}"
                  fi
                '')
                icfg.container.hostUsers)}
            ''
          }

          # Symlink bridge for interactive users (container mode only)
          ${lib.optionalString icfg.container.enable
            (lib.concatStringsSep "\n" (map (user: let
                userHome = config.users.users.${user}.home;
                symlinkPath = "${userHome}/.hermes";
                target = "${icfg.stateDir}/.hermes";
              in ''
                if [ -d "${symlinkPath}" ] && [ ! -L "${symlinkPath}" ]; then
                  _backup="${symlinkPath}.bak.$(date +%s)"
                  echo "hermes-agent-${name}: backing up existing ${symlinkPath} to $_backup"
                  mv "${symlinkPath}" "$_backup"
                fi
                ln -sfn "${target}" "${symlinkPath}"
                chown -h ${user}:${icfg.group} "${symlinkPath}"
              '')
              icfg.container.hostUsers))}

          # Seed auth file if provided
          ${lib.optionalString (icfg.authFile != null) ''
            ${
              if icfg.authFileForceOverwrite
              then ''
                install -o ${icfg.user} -g ${icfg.group} -m 0600 ${icfg.authFile} ${icfg.stateDir}/.hermes/auth.json
              ''
              else ''
                if [ ! -f ${icfg.stateDir}/.hermes/auth.json ]; then
                  install -o ${icfg.user} -g ${icfg.group} -m 0600 ${icfg.authFile} ${icfg.stateDir}/.hermes/auth.json
                fi
              ''
            }
          ''}

          # Seed .env from Nix-declared environment + environmentFiles.
          ${lib.optionalString (icfg.environment != {} || icfg.environmentFiles != []) ''
            ENV_FILE="${icfg.stateDir}/.hermes/.env"
            install -o ${icfg.user} -g ${icfg.group} -m 0640 /dev/null "$ENV_FILE"
            ${lib.optionalString (icfg.environment != {}) "cat ${ctx.envFile} > \"$ENV_FILE\""}
            ${lib.concatStringsSep "\n" (map (f: ''
                if [ -f "${f}" ]; then
                  echo "" >> "$ENV_FILE"
                  cat "${f}" >> "$ENV_FILE"
                fi
              '')
              icfg.environmentFiles)}
          ''}

          # Link documents into workspace
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (docName: _value: ''
              install -o ${icfg.user} -g ${icfg.group} -m 0640 ${ctx.documentDerivation}/${docName} ${icfg.workingDirectory}/${docName}
            '')
            icfg.documents)}

          # Declarative plugins — remove stale, link current
          find ${icfg.stateDir}/.hermes/plugins -maxdepth 1 -type l -name 'nix-managed-*' -delete 2>/dev/null || true

          ${lib.concatStringsSep "\n" (map (plugin: let
              pluginName = lib.getName plugin;
            in ''
              if [ ! -f "${plugin}/plugin.yaml" ]; then
                echo "ERROR: extraPlugins entry '${plugin}' has no plugin.yaml" >&2
                exit 1
              fi
              ln -sfn ${plugin} ${icfg.stateDir}/.hermes/plugins/nix-managed-${pluginName}
              chown -h ${icfg.user}:${icfg.group} ${icfg.stateDir}/.hermes/plugins/nix-managed-${pluginName}
            '')
            icfg.extraPlugins)}
        '';
      })
    instances);

    virtualisation = lib.mkMerge (lib.mapAttrsToList (_name: icfg:
      lib.mkIf (icfg.enable && icfg.container.enable) {
        docker.enable = lib.mkDefault (icfg.container.backend == "docker");
      })
    instances);
  };
}
