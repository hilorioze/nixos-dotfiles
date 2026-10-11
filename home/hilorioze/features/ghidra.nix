{pkgs, ...}: {
  home.packages = [
    (pkgs.ghidra.withExtensions (_: [
      pkgs.ghidra-mcp-plugin
    ]))
  ];
}
