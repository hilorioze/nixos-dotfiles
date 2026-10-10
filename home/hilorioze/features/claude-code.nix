{pkgs, ...}: {
  programs.claude-code = {
    enable = true;

    package = pkgs.unstablePkgs.claude-code;

    enableMcpIntegration = true;

    settings.attribution = false; # requires claude code 2.1.281+, which `unstablePkgs` always provides
  };
}
