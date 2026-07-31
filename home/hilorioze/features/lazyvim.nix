{
  # keep-sorted start
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [inputs.lazyvim-nix.homeManagerModules.default];

  programs.lazyvim = {
    enable = true;

    plugins = let
      mkPlugin = inputs.lazyvim-nix.lib.lazyConfig;
    in {
      # keep-sorted start block=yes newline_separated=yes
      autosave = mkPlugin {
        plugin = "okuuva/auto-save.nvim";

        opts = {};
      };

      conform = mkPlugin {
        plugin = "stevearc/conform.nvim";

        opts = {
          formatters.alejandra.command = lib.getExe pkgs.alejandra;

          formatters_by_ft.nix = ["alejandra"];
        };
      };

      snacks = mkPlugin {
        plugin = "folke/snacks.nvim";

        opts.picker.sources = {
          explorer.hidden = true;
          files.hidden = true;
          grep.hidden = true;
        };
      };
      # keep-sorted end
    };

    extras.lang.nix.enable = true;
  };
}
