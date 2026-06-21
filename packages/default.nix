{pkgs, ...}: {
  # keep-sorted start
  cli-proxy-api = pkgs.callPackage ./cli-proxy-api {};
  ghidra-mcp = pkgs.callPackage ./ghidra-mcp {};
  ghidra-mcp-plugin = pkgs.callPackage ./ghidra-mcp-plugin {};
  plasmavantage = pkgs.callPackage ./plasmavantage {};
  prometheus-podman-exporter = pkgs.callPackage ./prometheus-podman-exporter {};
  thermalmonitor = pkgs.callPackage ./thermalmonitor {};
  yaas = pkgs.callPackage ./yaas {};
  # keep-sorted end
}
