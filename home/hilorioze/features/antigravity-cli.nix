{pkgs, ...}: {
  programs.antigravity-cli = {
    enable = true;

    package = pkgs.unstablePkgs.antigravity-cli;

    enableMcpIntegration = true;

    settings = {
      allowNonWorkspaceAccess = true;

      artifactReviewPolicy = "always-proceed";
      toolPermission = "always-proceed";

      enableTelemetry = false;
      notifications = true;
    };
  };
}
