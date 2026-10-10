{pkgs, ...}: {
  programs.claude-code = {
    enable = true;

    package = pkgs.unstablePkgs.claude-code;

    enableMcpIntegration = true;
  };
}
