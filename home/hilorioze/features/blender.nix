{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.mcp.servers.blender = {
    command = lib.getExe pkgs.mcp-for-blender;

    env.BLENDER_MCP_DISABLE_TELEMETRY = "1"; # disable all telemetry, including usage statistics collected without consent
  };

  home.packages = let
    blender = pkgs.pkgsCuda.blender; # cycles renders on the gpu through cuda; the cuda variant comes from cache.nixos-cuda.org
  in [
    ((blender.withPackages (_: [pkgs.blender-openskp])).overrideAttrs (oldAttrs: {
      inherit (blender) pname; # keep the executable and desktop entry named `blender`

      installPhase =
        oldAttrs.installPhase
        + ''
          wrapProgram $out/bin/${blender.meta.mainProgram} \
            --prefix BLENDER_SYSTEM_SCRIPTS : ${pkgs.mcp-for-blender}/share/blender \
            --set BLENDER_SYSTEM_EXTENSIONS ${pkgs.blender-openskp}/share/blender/extensions \
            --set BLENDERMCP_NO_UPDATE_CHECK 1 \
            --add-flags '--addons blender_mcp,bl_ext.system.openskp_import_export'
        '';
    }))
  ];

  xdg.configFile."blender-mcp/consent_prompt.json".text = builtins.toJSON {
    prompt_version = 2;

    action = "decline"; # suppress only the consent prompt; collection is disabled through `BLENDER_MCP_DISABLE_TELEMETRY` above
  };
}
