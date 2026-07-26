{pkgs, ...}: {
  # keep-sorted start
  a2s = pkgs.callPackage ./a2s {};
  ghidra-mcp = pkgs.python3Packages.callPackage ./ghidra-mcp {};
  ghidra-mcp-plugin = pkgs.callPackage ./ghidra-mcp-plugin {};
  plasmavantage = pkgs.callPackage ./plasmavantage {};
  prometheus-podman-exporter = pkgs.callPackage ./prometheus-podman-exporter {};
  thermalmonitor = pkgs.callPackage ./thermalmonitor {};
  yaas = pkgs.callPackage ./yaas {};
  # keep-sorted end
}
