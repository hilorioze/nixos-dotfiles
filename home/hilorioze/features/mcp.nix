{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.mcp = {
    enable = true;

    servers = {
      # keep-sorted start block=yes newline_separated=yes
      ghidra.command = lib.getExe pkgs.ghidra-mcp;

      git.command = lib.getExe pkgs.mcp-server-git;

      nixos.command = lib.getExe pkgs.mcp-nixos;

      playwright = {
        command = lib.getExe pkgs.unstablePkgs.playwright-mcp;

        args = [
          "--extension"
          "--executable-path=${lib.getExe config.programs.chromium.package}"
        ];

        # prevent `nixpkgs`' wrapper from forcing isolated mode, which takes precedence over `--extension`
        env.PLAYWRIGHT_MCP_USER_DATA_DIR = "${config.xdg.stateHome}/playwright";
      };
      # keep-sorted end
    };
  };
}
