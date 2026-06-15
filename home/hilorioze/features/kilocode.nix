{
  # keep-sorted start
  config,
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  sops.secrets = {
    # keep-sorted start
    "credentials/kilo/api-key" = {};
    "credentials/modal/api-key" = {};
    "credentials/openrouter/api-key" = {};
    # keep-sorted end
  };

  home.sessionVariables.KILO_EXPERIMENTAL = true;

  xdg.configFile."kilo/kilo.json".text = builtins.toJSON {
    "$schema" = "https://app.kilo.ai/config.json";

    # https://github.com/nix-community/home-manager/blob/8aec76cc1e045f37b55d82ca3cee4910ae04d3db/modules/programs/opencode.nix#L21-L55
    mcp =
      lib.mapAttrs
      (_: server: let
        isRemote = server ? url && server.url != null;
        isLocal = server ? command && server.command != null;
        renderedEnv = lib.hm.mcp.renderEnv (p: "{file:${p}}") (server.env or {});
      in
        {
          enabled = !(server.disabled or false);
        }
        // (
          if isRemote
          then
            {
              type = "remote";
              inherit (server) url;
            }
            // lib.optionalAttrs ((server.headers or {}) != {}) {
              inherit (server) headers;
            }
          else if isLocal
          then
            {
              type = "local";
              command = [server.command] ++ (server.args or []);
            }
            // lib.optionalAttrs (renderedEnv != {}) {
              environment = renderedEnv;
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

      kilo = {
        npm = "@kilocode/kilo-gateway";

        name = "Kilo Gateway";

        options.apiKey = "{file:${config.sops.secrets."credentials/kilo/api-key".path}}";
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

      openrouter = {
        npm = "@openrouter/ai-sdk-provider";

        name = "OpenRouter";

        options.apiKey = "{file:${config.sops.secrets."credentials/openrouter/api-key".path}}";
      };
      # keep-sorted end
    };
  };
}
