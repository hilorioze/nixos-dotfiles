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
      deepwiki.url = "https://mcp.deepwiki.com/mcp";

      devenv.url = "https://mcp.devenv.sh";

      git = {
        command = lib.getExe' pkgs.uv "uvx";
        args = ["mcp-server-git"];
      };

      nixos.command = lib.getExe pkgs.mcp-nixos;

      ghidra.command = lib.getExe pkgs.ghidra-mcp;

      playwright = {
        command = lib.getExe pkgs.playwright-mcp;

        # keep playwright's browser profile in a writable state dir to avoid the nix store mkdir failure since https://github.com/NixOS/nixpkgs/commit/7cc8a6b08a51d3fd23b9c4fd2493e7e888e88507#diff-cbef874c9961078638cf55b7fca92790722964580fec608f68ebb93f7c458c7dL32; also persists state across sessions
        env.PLAYWRIGHT_MCP_USER_DATA_DIR = "${config.xdg.stateHome}/playwright";
      };
      # keep-sorted end
    };
  };
}
