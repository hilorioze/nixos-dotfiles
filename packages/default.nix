{pkgs, ...}: {
  # keep-sorted start
  ghidra-mcp = pkgs.callPackage ./ghidra-mcp {};
  ghidra-mcp-plugin = pkgs.callPackage ./ghidra-mcp-plugin {};
  plasmavantage = pkgs.callPackage ./plasmavantage {};
  thermalmonitor = pkgs.callPackage ./thermalmonitor {};
  yaas = pkgs.callPackage ./yaas {};
  # keep-sorted end
}
