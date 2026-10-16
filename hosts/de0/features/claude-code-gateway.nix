{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
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

      LoadCredential = [
        # keep-sorted start
        "inference-key:${config.sops.secrets."services/cliproxyapi/inference-key".path}"
        "management-key:${config.sops.secrets."services/cliproxyapi/management-key".path}"
        # keep-sorted end
      ];

      Restart = "always";
      RestartSec = 2;
    };
  };
}
