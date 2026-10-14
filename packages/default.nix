{pkgs, ...}: {
  # keep-sorted start
  a2s = pkgs.callPackage ./a2s {};
  blutter = pkgs.callPackage ./blutter {};
  bspguy = pkgs.callPackage ./bspguy {};
  claude-code-gateway = pkgs.callPackage ./claude-code-gateway {};
  claude-code-status-line = pkgs.callPackage ./claude-code-status-line {};
  claude-code-with-node = pkgs.callPackage ./claude-code-with-node {};
  cliproxyapi-accounts = pkgs.python3Packages.callPackage ./cliproxyapi-accounts {};
  cliproxyapi-warmup = pkgs.callPackage ./cliproxyapi-warmup {};
  codeburn-desktop = pkgs.callPackage ./codeburn-desktop {};
  codex-with-node = pkgs.callPackage ./codex-with-node {};
  deadlocked = pkgs.callPackage ./deadlocked {};
  deadlocked-relay = pkgs.callPackage ./deadlocked-relay {};
  ghidra-mcp = pkgs.python3Packages.callPackage ./ghidra-mcp {};
  ghidra-mcp-plugin = pkgs.callPackage ./ghidra-mcp-plugin {};
  half-life-asset-manager = pkgs.callPackage ./half-life-asset-manager {};
  plasmavantage = pkgs.callPackage ./plasmavantage {};
  playwright-mcp-with-extension-token = pkgs.callPackage ./playwright-mcp-with-extension-token {};
  prometheus-podman-exporter = pkgs.callPackage ./prometheus-podman-exporter {};
  quickshare = pkgs.callPackage ./quickshare {};
  steam-broker = pkgs.callPackage ./steam-broker {};
  thermalmonitor = pkgs.callPackage ./thermalmonitor {};
  yaas = pkgs.callPackage ./yaas {inherit (pkgs.unstablePkgs) flutter347;};
  # keep-sorted end
}
