{inputs, ...}: {
  imports = [inputs.lazyvim-nix.homeManagerModules.default];

  programs.lazyvim = {
    enable = true;

    plugins = let
      mkPlugin = inputs.lazyvim-nix.lib.lazyConfig;
    in {
      # keep-sorted start block=yes newline_separated=yes
      autosave = mkPlugin {
        plugin = "okuuva/auto-save.nvim";
      };

      conform = mkPlugin {
        plugin = "stevearc/conform.nvim";

        opts.formatters_by_ft.nix = ["alejandra"];
      };
      # keep-sorted end
    };

    extras.lang.nix.enable = true;
  };
}
