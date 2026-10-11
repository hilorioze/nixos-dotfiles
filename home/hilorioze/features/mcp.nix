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

      playwright = {
        command = lib.getExe pkgs.playwright-mcp-with-extension-token;

        args = [
          "--extension"
          "--executable-path=${lib.getExe config.programs.chromium.package}"

          # keep snapshots and console logs out of the workspace (defaults to `./.playwright-mcp`)
          "--output-dir=${config.xdg.cacheHome}/playwright-mcp"
        ];

        env = {
          # drop the client's library path (e.g. `claude-code`'s `alsa-lib`), which can break launching the browser built against another `glibc`
          LD_LIBRARY_PATH = "";

          # prevent `nixpkgs`' wrapper from forcing isolated mode, which takes precedence over `--extension`;
          # must be the profile that has the extension, since `--extension` opens its connect page with this `--user-data-dir`
          PLAYWRIGHT_MCP_USER_DATA_DIR = "${config.xdg.configHome}/chromium";
        };
      };
      # keep-sorted end
    };
  };
}
