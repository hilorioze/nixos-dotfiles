{pkgs, ...}: {
  home.packages = [
    (pkgs.symlinkJoin {
      name = "ghidra-with-mcp";

      paths = [
        (pkgs.ghidra.withExtensions (_: [
          pkgs.ghidra-mcp-plugin
        ]))
      ];

      nativeBuildInputs = [pkgs.makeWrapper];

      # the plugin only allows script execution when this is set for the ghidra process
      postBuild = ''
        wrapProgram $out/bin/${pkgs.ghidra.meta.mainProgram} --set GHIDRA_MCP_ALLOW_SCRIPTS 1
      '';
    })
  ];
}
