{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "cliproxyapi-login";

      runtimeInputs = [
        # keep-sorted start
        pkgs.jq
        pkgs.moreutils
        pkgs.unstablePkgs.cliproxyapi
        # keep-sorted end
      ];

      text = ''
        provider=$1

        state_directory=${config.xdg.stateHome}/${config.systemd.user.services.cliproxyapi.Service.StateDirectory}

        cliproxyapi --config $state_directory/config.yaml --$provider-login

        # the prefix pins a model to its provider; claude asks for bare ids
        for file in $state_directory/auth/*.json; do
          jq 'if .type == "claude" then . else .prefix = .type end' $file | sponge $file
        done
      '';
    })
  ];

  systemd.user.services.cliproxyapi = {
    Install.WantedBy = ["default.target"];

    Unit.Description = "CLIProxyAPI subscription proxy";

    Service = {
      StateDirectory = "cliproxyapi";
      StateDirectoryMode = "0700";

      ExecStartPre = let
        settings = (pkgs.formats.json {}).generate "cliproxyapi-config.json" {
          server = {
            host = "127.0.0.1";
            port = 8317; # without it the port is random

            commercial-mode = true; # no request log with prompts on disk
          };

          management.disable-control-panel = true; # the panel is downloaded from github

          routing = {
            force-model-prefix = true; # a prefixed account serves only models asked with its prefix

            session-affinity = true; # prompt cache is per account; round-robin loses it on every switch
          };

          multimedia.disable-image-generation = "chat"; # claude drops the image, the quota is spent anyway
        };
      in
        lib.getExe (pkgs.writeShellApplication {
          name = "cliproxyapi-write-config";

          runtimeInputs = [
            # keep-sorted start
            pkgs.coreutils
            pkgs.jq
            # keep-sorted end
          ];

          # cliproxyapi hashes the management key in place, the plain one stays in its file
          text = ''
            for key in inference-key management-key; do
              [[ -s $STATE_DIRECTORY/$key ]] || head --bytes=32 /dev/urandom | basenc --base16 --wrap=0 > $STATE_DIRECTORY/$key
            done

            jq \
              --rawfile inference_key $STATE_DIRECTORY/inference-key \
              --rawfile management_key $STATE_DIRECTORY/management-key \
              '.access."api-keys" = [$inference_key] | .management."secret-key" = $management_key | .oauth."auth-dir" = "\(env.STATE_DIRECTORY)/auth"' \
              ${settings} > $STATE_DIRECTORY/config.yaml
          '';
        });

      ExecStart = "${lib.getExe pkgs.unstablePkgs.cliproxyapi} --config \${STATE_DIRECTORY}/config.yaml";

      Restart = "always";
      RestartSec = 2;
    };
  };
}
