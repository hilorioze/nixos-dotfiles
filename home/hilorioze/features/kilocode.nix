{
  # keep-sorted start
  config,
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  sops.secrets."credentials/modal/api-key" = {};

  home.sessionVariables.KILO_EXPERIMENTAL = true;

  xdg.configFile."kilo/kilo.json".text = builtins.toJSON {
    "$schema" = "https://app.kilo.ai/config.json";

    # https://github.com/nix-community/home-manager/blob/a7a415883195ffbd4dabec8f098f201e6eaaadf8/modules/programs/opencode.nix#L21-L48
    mcp =
      lib.mapAttrs
      (_: server:
        {
          enabled = !(server.disabled or false);
        }
        // (
          if server ? url
          then
            {
              type = "remote";
              inherit (server) url;
            }
            // lib.optionalAttrs (server ? headers) {
              inherit (server) headers;
            }
          else if server ? command
          then
            {
              type = "local";
              command = [server.command] ++ (server.args or []);
            }
            // lib.optionalAttrs (server ? env) {
              environment = server.env;
            }
          else {}
        ))
      config.programs.mcp.servers;

    plugin = let
      wakatimePackageJson = builtins.fromJSON (
        builtins.readFile "${inputs.opencode-wakatime}/package.json"
      );
    in ["${wakatimePackageJson.name}@${wakatimePackageJson.version}"];

    provider = {
      # keep-sorted start block=yes newline_separated=yes
      cli-proxy-api = {
        npm = "@ai-sdk/openai-compatible";

        name = "CLI Proxy API";

        options.baseURL = "http://127.0.0.1:8317/v1";

        models = {
          # keep-sorted start block=yes newline_separated=yes
          claude-opus-4-6-thinking = {
            name = "Claude Opus 4.6";

            reasoning = true;
          };

          gemini-3-flash-agent = {
            name = "Gemini 3.5 Flash";

            reasoning = true;
          };

          gemini-pro-agent = {
            name = "Gemini 3.1 Pro";

            reasoning = true;
          };
          # keep-sorted end
        };
      };

      modal = {
        npm = "@ai-sdk/openai-compatible";

        name = "Modal";

        options = {
          baseURL = "https://api.us-west-2.modal.direct/v1";

          apiKey = "{file:${config.sops.secrets."credentials/modal/api-key".path}}";
        };

        models = {
          # keep-sorted start block=yes newline_separated=yes
          "zai-org/GLM-5-FP8" = {
            name = "GLM-5";

            reasoning = true;
          };

          "zai-org/GLM-5.1-FP8" = {
            name = "GLM-5.1";

            reasoning = true;
          };
          # keep-sorted end
        };
      };
      # keep-sorted end
    };
  };
}
