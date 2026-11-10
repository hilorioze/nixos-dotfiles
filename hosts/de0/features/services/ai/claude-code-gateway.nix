{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets = {
    "services/cliproxyapi/management-key".restartUnits = ["claude-code-gateway.service"];

    "services/cliproxyapi/users/claude-code-gateway/inference-key".restartUnits = ["claude-code-gateway.service"];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.claude-code-gateway = {
      entryPoints = ["https"];
      rule = "Host(`claude-code-gateway.${config.networking.fqdn}`) && !PathRegexp(`^/v[0-9]+/management`)"; # cliproxyapi takes relayed management calls as local ones

      service = "claude-code-gateway";
    };

    services.claude-code-gateway.loadBalancer.servers = [{url = "http://${config.systemd.services.claude-code-gateway.environment.CLAUDE_CODE_GATEWAY_HOST}:${config.systemd.services.claude-code-gateway.environment.CLAUDE_CODE_GATEWAY_PORT}";}];
  };

  systemd.services.claude-code-gateway = {
    wantedBy = ["multi-user.target"];

    after = ["cliproxyapi.service"];

    environment = {
      CLAUDE_CODE_GATEWAY_HOST = "127.0.0.1";
      CLAUDE_CODE_GATEWAY_PORT = "8318";

      inherit (config.systemd.services.cliproxyapi-warmup.environment) CLIPROXYAPI_ANTIGRAVITY_USER_AGENT CLIPROXYAPI_CODEX_HEADERS CLIPROXYAPI_URL;
    };

    serviceConfig = {
      ExecStart = lib.getExe pkgs.claude-code-gateway;

      DynamicUser = true;
      StateDirectory = "claude-code-gateway";

      LoadCredential = [
        "management-key:${config.sops.secrets."services/cliproxyapi/management-key".path}"

        "inference-key:${config.sops.secrets."services/cliproxyapi/users/claude-code-gateway/inference-key".path}"
      ];

      Restart = "always";
      RestartSec = 2;
    };
  };
}
