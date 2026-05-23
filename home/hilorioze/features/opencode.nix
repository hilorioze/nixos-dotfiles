{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/opencode.nix];

  sops.secrets."credentials/modal/api-key".sopsFile = ../secrets.yaml;

  home.sessionVariables = {
    # keep-sorted start
    OPENCODE_ENABLE_EXA = "true";
    OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    # keep-sorted end
  };

  programs.opencode = {
    enableMcpIntegration = true;

    settings = {
      autoupdate = false;

      plugin = let
        wakatimePackageJson = builtins.fromJSON (
          builtins.readFile "${inputs.opencode-wakatime}/package.json"
        );
      in ["${wakatimePackageJson.name}@${wakatimePackageJson.version}"];

      provider.modal = {
        npm = "@ai-sdk/openai-compatible";

        name = "Modal";

        options = {
          baseURL = "https://api.us-west-2.modal.direct/v1";

          apiKey = "{file:${config.sops.secrets."credentials/modal/api-key".path}}";
        };

        models."zai-org/GLM-5.1-FP8".name = "GLM-5.1";
      };
    };
  };
}
