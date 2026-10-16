{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = ["${inputs.nixpkgs-unstable}/nixos/modules/services/misc/cliproxyapi.nix"]; # not in 26.05

  documentation.nixos.enable = false; # the module's manual chapter has redirect ids that 26.05 doesn't know

  sops.secrets = {
    # keep-sorted start
    "services/cliproxyapi/inference-key" = {};
    "services/cliproxyapi/management-key" = {};
    # keep-sorted end
  };

  services.cliproxyapi = {
    enable = true;

    package = pkgs.unstablePkgs.cliproxyapi;

    settings = {
      server = {
        host = "0.0.0.0"; # the firewall keeps the port off the internet; tailscale accepts tailnet traffic before it gets there

        commercial-mode = true; # with `request-log` off, failed requests still get written to disk with their prompts
      };

      access.api-keys = [{_secret = config.sops.secrets."services/cliproxyapi/inference-key".path;}];

      management = {
        secret-key._secret = config.sops.secrets."services/cliproxyapi/management-key".path;

        disable-control-panel = true; # the panel is downloaded from github
      };

      routing = {
        force-model-prefix = true; # a prefixed account serves only models asked with its prefix

        session-affinity = true; # prompt cache is per account; round-robin loses it on every switch
      };

      multimedia.disable-image-generation = "chat"; # cliproxyapi adds an image tool to codex requests; claude drops the images, the quota is spent anyway
    };
  };

  # starts 5h windows when the learned demand gets the most out of them, longer ones once the 5h one runs; routes to the account whose 5h window resets soonest
  systemd.services.cliproxyapi-warmup = {
    wantedBy = ["multi-user.target"];

    after = ["cliproxyapi.service"];

    environment = {
      CLIPROXYAPI_URL = "http://127.0.0.1:${toString config.services.cliproxyapi.settings.server.port}"; # management answers only local callers

      # let quota requests send the same `User-Agent` and `Originator` as cliproxyapi does with its own codex requests
      CLIPROXYAPI_CODEX_HEADERS = pkgs.runCommand "cliproxyapi-codex-headers.json" {nativeBuildInputs = [pkgs.jq];} ''
        read_constant() {
          grep --only-matching --perl-regexp "^\s*$1\s*=\s*\"\K[^\"]+" ${config.services.cliproxyapi.package.src}/internal/runtime/executor/codex_executor_request.go
        }

        user_agent=$(read_constant codexUserAgent)
        originator=$(read_constant codexOriginator)

        jq --null-input --arg user_agent "$user_agent" --arg originator "$originator" '{"User-Agent": $user_agent, Originator: $originator}' > $out
      '';

      # let antigravity quota requests pass as agy: daily-cloudcode-pa lists the gemini group only for a recent `antigravity/cli/<version>`
      CLIPROXYAPI_ANTIGRAVITY_USER_AGENT = "antigravity/cli/${pkgs.unstablePkgs.antigravity-cli.version}";
    };

    serviceConfig = {
      ExecStart = lib.getExe pkgs.cliproxyapi-warmup;

      DynamicUser = true;
      StateDirectory = "cliproxyapi-warmup";

      LoadCredential = ["management-key:${config.sops.secrets."services/cliproxyapi/management-key".path}"];

      Restart = "always";
      RestartSec = 2;
    };
  };

  # `sudo --user cliproxyapi cliproxyapi-login <provider>`: the token has to land in the service's own directory
  # open the printed url locally and paste the localhost url it redirects to when the login asks
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "cliproxyapi-login";

      runtimeInputs = with pkgs; [
        # keep-sorted start
        config.services.cliproxyapi.package
        jq
        moreutils
        # keep-sorted end
      ];

      text = ''
        provider=$1

        # the service can't rewrite a token file written as root, so after a restart it reads a refresh token that was already rotated
        if [[ $(id --user --name) != ${config.systemd.services.cliproxyapi.serviceConfig.User} ]]; then
          echo "run as the service user: sudo --user ${config.systemd.services.cliproxyapi.serviceConfig.User} cliproxyapi-login $provider" >&2

          exit 1
        fi

        # cliproxyapi fails to get its working directory when the service user can't enter it, such as the home `sudo` comes from
        cd ${config.systemd.services.cliproxyapi.serviceConfig.WorkingDirectory}

        cliproxyapi --config ${config.systemd.services.cliproxyapi.serviceConfig.WorkingDirectory}/config.yaml --no-browser --$provider-login

        # the prefix pins a model to its provider; claude asks for bare ids
        for file in ${config.services.cliproxyapi.settings.oauth.auth-dir}/*.json; do
          jq 'if .type == "claude" then . else .prefix = .type end' $file | sponge $file
        done
      '';
    })
  ];
}
